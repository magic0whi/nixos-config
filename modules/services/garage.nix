# TIP: Manually setup a Nix binary cache server
# 1. Get node id: `sudo garage node id`
# 2. Input rpc secret: `export GARAGE_RPC_SECRET=$(systemd-ask-password)`
# 3. Initialize single-node layout: `-h $ID@127.0.0.1:3901 layout assign $ID -z us-east-1 -c 200G -t <hostname>`
# 4. Commit layout: `garage -h $ID@127.0.0.1:3901 layout apply --version 1`
# 5. Create the bucket: `garage -h <full-node-id>@127.0.0.1:3901 bucket create nix-cache`
# 6. Create the access key: `garage -h <full-node-id>@127.0.0.1:3901 key create nixbuilder`
# 7. Allow the key to access the bucket:
#   `garage -h <full-node-id>@127.0.0.1:3901 bucket allow --read --write --owner nix-cache --key nixbuilder`
# 8. Allow bucket-as-website bucket-as-website: garage -h <full-node-id>@127.0.0.1:3901 bucket website --allow nix-cache
{
  config,
  lib,
  mylib,
  const,
  pkgs,
  ...
}:
let
  hostname = config.networking.hostName;
  garage_settings = config.services.garage.settings;
in
{
  vars.hostAddrs.${hostname} =
    let
      subdomains =
        let
          subs = [
            "${hostname}.s3"
            "*.${hostname}.s3"
            "${hostname}.s3-pub"
            "*.${hostname}.s3-pub"
            "${hostname}.garage"
          ];
        in
        {
          A = subs;
          AAAA = subs;
        };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };

  sops =
    let
      restartUnits = [ "garage.service" ];
    in
    {
      secrets = {
        garage_rpc_secret = { inherit restartUnits; };
        garage_admin_token = { inherit restartUnits; };
      };
      templates."garage.env" = {
        inherit restartUnits;
        content = mylib.toEnv {
          GARAGE_RPC_SECRET = config.sops.placeholder.garage_rpc_secret;
          GARAGE_ADMIN_TOKEN = config.sops.placeholder.garage_admin_token;
          # TODO: For Prometheus
          # GARAGE_METRICS_TOKEN = "";
        };
      };
      templates."garage-webui.env" = {
        restartUnits = [ "garage-webui.service" ];
        content = mylib.toEnv {
          # garage-webui default use rpc_public_addr to access admin API
          API_BASE_URL = "http://${garage_settings.admin.api_bind_addr}";
          API_ADMIN_KEY = config.sops.placeholder.garage_admin_token;
        };
      };
    };

  systemd.services.garage.serviceConfig.EnvironmentFile = config.sops.templates."garage.env".path;

  services.garage = {
    enable = true;
    package = pkgs.garage_2;
    # https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/
    settings = {
      metadata_auto_snapshot_interval = "6h";
      disable_scrub = true; # ZFS/Btrfs will take this job
      rpc_bind_addr = lib.mkDefault "127.0.0.1:3901";
      # s3_api (3900) is for common access
      s3_api = {
        api_bind_addr = "127.0.0.1:3900";
        root_domain = ".${lib.toLower hostname}.s3.${const.domain}";
      };
      # s3_web (3902) is for bucket-as-website
      s3_web = {
        bind_addr = "127.0.0.1:3902";
        root_domain = ".${lib.toLower hostname}.s3-pub.${const.domain}";
      };
      # admin (3903) is for webui access
      admin.api_bind_addr = "127.0.0.1:3903";
      replication_factor = lib.mkDefault 1;
      compression_level = 0; # A value of 0 will let zstd choose a default value (currently 3)
    };
  };

  systemd.services.garage-webui = {
    description = "Garage Web UI";
    after = [
      "network.target"
      "network-online.target"
    ];
    wants = [
      "network.target"
      "network-online.target"
    ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      PORT = "3999"; # the type check only allow string
      CONFIG_PATH = "${(pkgs.formats.toml { }).generate "config.toml" garage_settings}";
    };
    serviceConfig = {
      ExecStart = lib.getExe pkgs.garage-webui;
      Restart = "on-failure";
      EnvironmentFile = config.sops.templates."garage-webui.env".path;
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers = {
      s3 = {
        rule = lib.concatStringsSep " || " [
          "Host(`${hostname}.s3.${const.domain}`)"
          # (?i) make the regex case-insensitive
          ''HostRegexp(`(?i)^[^.]+\.${lib.toLower hostname}\.s3\.${lib.escapeRegex const.domain}$`)''
        ];
        entryPoints = [ "websecure" ];
        service = "s3";
        tls = { };
      };
      s3-pub = {
        rule = lib.concatStringsSep " || " [
          "Host(`${hostname}.s3-pub.${const.domain}`)"
          ''HostRegexp(`(?i)^[^.]+\.${lib.toLower hostname}\.s3-pub\.${lib.escapeRegex const.domain}$`)''
        ];
        entryPoints = [ "websecure" ];
        service = "s3-pub";
        tls = { };
      };
      garage-webui = {
        rule = "Host(`${hostname}.garage.${const.domain}`)";
        entryPoints = [ "websecure" ];
        middlewares = [ "authelia-auth" ];
        service = "garage-webui";
        tls = { };
      };
    };
    services =
      let
        healthCheck = {
          port = toString (mylib.getUriPort garage_settings.admin.api_bind_addr);
          path = "/health";
        };
      in
      {
        s3.loadBalancer = {
          servers = [ { url = "http://${garage_settings.s3_api.api_bind_addr}"; } ]; # Default :3900
          # Probe the admin port
          inherit healthCheck;
        };
        s3-pub.loadBalancer = {
          servers = [ { url = "http://${garage_settings.s3_web.bind_addr}"; } ]; # Default :3902
          # Probe the admin port
          inherit healthCheck;
        };
        garage-webui.loadBalancer.servers = lib.singleton {
          url = "http://127.0.0.1:${config.systemd.services.garage-webui.environment.PORT}"; # Default :3909
        };
      };
  };
}

## Manually setup a Nix binary cache server
# 1. Get node id: `sudo garage node id`
# 2. Input rpc secret: `export GARAGE_RPC_SECRET=$(systemd-ask-password)`
# 3. Initialize single-node layout: `-h <full-node-id>@127.0.0.1:3901 layout assign -z cn-east1-a -c 200G <node-ids>`
# 4. Commit layout: `garage -h <full-node-id>@127.0.0.1:3901 layout apply --version 1`
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
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains =
        let
          subs = [
            "*.s3"
            "*.s3-pub"
            "s3"
            "s3-pub"
            "garage"
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
      sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
    in
    {
      secrets = {
        "garage_rpc_secret" = { inherit restartUnits sopsFile; };
        "garage_admin_token" = { inherit restartUnits sopsFile; };
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
        content = mylib.toEnv { API_ADMIN_KEY = config.sops.placeholder.garage_admin_token; };
      };
    };
  # systemd.tmpfiles.settings."10-garage-create-dir" = {
  #   ${config.services.garage.settings.data_dir}.d = {
  #     group = "storage";
  #     mode = "2775";
  #   };
  #   ${config.services.garage.settings.metadata_dir}.d = {
  #     group = "storage";
  #     mode = "2775";
  #   };
  # };
  systemd.services.garage = {
    unitConfig.RequiresMountsFor = [ const.storagePath ];
    serviceConfig = {
      EnvironmentFile = config.sops.templates."garage.env".path;
      SupplementaryGroups = [ "storage" ];
      # `DynamicUser=true` implies `ProtectSystem=strict`
      # `metadata_dir` is added defaultly, ref:
      # https://github.com/NixOS/nixpkgs/blob/15f4ee454b1dce334612fa6843b3e05cf546efab/nixos/modules/services/web-servers/garage.nix#L127-L149
      ReadWritePaths = [ "${const.storagePath}/garage/snapshots" ];
    };
  };
  services.garage = {
    enable = true;
    package = pkgs.garage_2;
    # https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/
    settings = {
      # metadata_dir = "${const.storagePath}/garage/meta"; # Garage recommends placing metadata on SSD
      metadata_snapshots_dir = "${const.storagePath}/garage/snapshots";
      metadata_auto_snapshot_interval = "6h";
      disable_scrub = true; # ZFS will take this job
      data_dir = "${const.storagePath}/garage/data";
      rpc_bind_addr = "127.0.0.1:3901";
      rpc_public_addr = "127.0.0.1:3901";
      # s3_api (3900) is for common access
      s3_api = {
        api_bind_addr = "127.0.0.1:3900";
        root_domain = ".s3.${const.domain}";
        s3_region = "cn-east1-a";
      };
      # s3_web (3902) is for bucket-as-website
      s3_web = {
        bind_addr = "127.0.0.1:3902";
        root_domain = ".s3-pub.${const.domain}";
      };
      # admin (3903) is for webui access
      admin = {
        api_bind_addr = "127.0.0.1:3903";
      };
      replication_factor = 1;
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
    serviceConfig = {
      ExecStart = lib.getExe pkgs.garage-webui;
      Restart = "on-failure";
      EnvironmentFile = config.sops.templates."garage-webui.env".path;
      Environment = [
        "PORT=3909"
        "CONFIG_PATH=${(pkgs.formats.toml { }).generate "config.toml" config.services.garage.settings}"
      ];
    };
  };
  services.traefik.dynamicConfigOptions.http = {
    routers = {
      s3 = {
        rule = ''Host(`s3.${const.domain}`) || HostRegexp(`^[^.]+\.s3\.${lib.escapeRegex const.domain}$`)'';
        entryPoints = [ "websecure" ];
        service = "s3";
        tls = { };
      };
      s3-pub = {
        rule = ''Host(`s3-pub.${const.domain}`) || HostRegexp(`^[^.]+\.s3-pub\.${lib.escapeRegex const.domain}$`)'';
        entryPoints = [ "websecure" ];
        service = "s3-pub";
        tls = { };
      };
      garage-webui = {
        rule = "Host(`garage.${const.domain}`)";
        entryPoints = [ "websecure" ];
        middlewares = [ "authelia-auth" ];
        service = "garage-webui";
        tls = { };
      };
    };
    services = {
      s3.loadBalancer =
        let
          cfg = config.services.garage.settings;
        in
        {
          servers = [ { url = "http://${cfg.s3_api.api_bind_addr}"; } ]; # Default :3900
          # Probe the admin port
          healthCheck = {
            port = toString (mylib.getUriPort cfg.admin.api_bind_addr);
            path = "/health";
          };
        };
      s3-pub.loadBalancer =
        let
          cfg = config.services.garage.settings;
        in
        {
          servers = [ { url = "http://${cfg.s3_web.bind_addr}"; } ]; # Default :3902
          # Probe the admin port
          healthCheck = {
            port = toString (mylib.getUriPort cfg.admin.api_bind_addr);
            path = "/health";
          };
        };
      garage-webui.loadBalancer.servers = lib.singleton {
        url =
          let
            find_first_prefix = key: list: builtins.elemAt list (lib.lists.findFirstIndex (i: lib.hasPrefix key i) null list);
            port = lib.last (
              lib.splitString "=" (find_first_prefix "PORT=" config.systemd.services.garage-webui.serviceConfig.Environment)
            );
          in
          "http://127.0.0.1:${port}"; # Default :3909
      };
    };
  };
}

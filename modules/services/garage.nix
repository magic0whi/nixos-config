# Ref: https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/
#
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
  vars.hostAddrs.${hostname}.easytier.subdomains =
    let
      subs = [
        "${hostname}.s3"
        "*.${hostname}.s3"
        "${hostname}.s3-pub"
        "*.${hostname}.s3-pub"
        "${hostname}.garage"
        "admin-api-${hostname}.garage"
      ];
    in
    {
      A = subs;
      AAAA = subs;
    };

  sops =
    let
      restartUnits = [ "garage.service" ];
    in
    {
      secrets = {
        garage_rpc_secret = { inherit restartUnits; };
        garage_admin_token = { inherit restartUnits; };
        prometheus_bearer_token = { inherit restartUnits; };
      };
      templates."garage.env" = {
        inherit restartUnits;
        content = mylib.toEnv {
          GARAGE_RPC_SECRET = config.sops.placeholder.garage_rpc_secret;
          GARAGE_ADMIN_TOKEN = config.sops.placeholder.garage_admin_token;
          GARAGE_METRICS_TOKEN = config.sops.placeholder.prometheus_bearer_token;
        };
      };
      templates."garage-ui.env" = {
        restartUnits = [ "${config.virtualisation.oci-containers.containers.garage-ui.serviceName}.service" ];
        content = mylib.toEnv { GARAGE_UI_GARAGE_ADMIN_TOKEN = config.sops.placeholder.garage_admin_token; };
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
      # admin (3903) is for garage-ui access
      admin.api_bind_addr = "127.0.0.1:3903";
      replication_factor = lib.mkDefault 1;
      compression_level = 0; # A value of 0 will let zstd choose a default value (currently 3)
    };
  };

  virtualisation.oci-containers.containers.garage-ui = {
    # Ref: https://hub.docker.com/r/noooste/garage-ui/tags
    image = "docker.io/noooste/garage-ui:v0.14.0@sha256:e4a33c448304a3f6e60f08d6aa71b2471fd79ac870a5c7e178ea247dea3238b3";
    extraOptions = [ "--network=host" ]; # Use the host network to reach Garage that listening on loopback
    environmentFiles = [ config.sops.templates."garage-ui.env".path ];
    # Environment variables must be strings in Nix
    environment = {
      GARAGE_UI_SERVER_HOST = "127.0.0.1";
      GARAGE_UI_SERVER_PORT = "3909";
      GARAGE_UI_SERVER_ENVIRONMENT = "production";
      GARAGE_UI_SERVER_ROOT_URL = "https://${hostname}.garage.${const.domain}";
      GARAGE_UI_GARAGE_ENDPOINT = "http://${garage_settings.s3_api.api_bind_addr}";
      GARAGE_UI_GARAGE_ADMIN_ENDPOINT = "http://${garage_settings.admin.api_bind_addr}";
      GARAGE_UI_GARAGE_REGION = garage_settings.s3_api.s3_region;
    };
    volumes = [ "garage-ui:/app/data" ]; # Persist the generated JWT signing key so logins survive container recreation
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
      garage-ui = {
        rule = "Host(`${hostname}.garage.${const.domain}`)";
        entryPoints = [ "websecure" ];
        middlewares = [ "authelia-auth" ];
        service = "garage-ui";
        tls = { };
      };
      # For metrics
      garage-admin-api = {
        rule = "Host(`admin-api-${hostname}.garage.${const.domain}`)";
        entryPoints = [ "websecure" ];
        service = "garage-admin-api";
        tls = { };
      };
    };
    services =
      let
        # Probe the admin port
        healthCheck = {
          port = toString (mylib.getUriPort garage_settings.admin.api_bind_addr);
          path = "/health";
        };
      in
      {
        s3.loadBalancer = {
          servers = [ { url = "http://${garage_settings.s3_api.api_bind_addr}"; } ]; # Default :3900
          inherit healthCheck;
        };
        s3-pub.loadBalancer = {
          servers = [ { url = "http://${garage_settings.s3_web.bind_addr}"; } ]; # Default :3902
          inherit healthCheck;
        };
        garage-ui.loadBalancer.servers = lib.singleton {
          url = "http://127.0.0.1:${config.virtualisation.oci-containers.containers.garage-ui.environment.GARAGE_UI_SERVER_PORT}";
        };
        garage-admin-api.loadBalancer = {
          servers = [ { url = "http://${garage_settings.admin.api_bind_addr}"; } ]; # Default :3903
          inherit healthCheck;
        };
      };
  };
}

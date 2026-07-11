{
  config,
  const,
  lib,
  mylib,
  pkgs,
  machineConfigs,
  ...
}:
let
  hostname = config.networking.hostName;

  hostname_psql = const.networking.findFirstHostBySubdomain "psql";
  machine_config_psql = machineConfigs.${hostname_psql}.config;
in
{
  vars.hostAddrs.${hostname} =
    let
      subdomains = {
        A = [ "homebox" ];
        AAAA = [ "homebox" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };

  sops =
    let
      restartUnits = [ "homebox.service" ];
      sopsFile = "${const.secretsDir}/${hostname}.sops.yaml";
    in
    {
      secrets = {
        homebox_oidc_client_secret = { inherit restartUnits sopsFile; };
        homebox_db_password = { inherit restartUnits sopsFile; };
      };
      templates."homebox.env" = {
        inherit restartUnits;
        content = mylib.toEnv {
          HBOX_OIDC_CLIENT_SECRET = config.sops.placeholder.homebox_oidc_client_secret;
          HBOX_DATABASE_PASSWORD = config.sops.placeholder.homebox_db_password;
        };
      };
    };
  systemd.services.homebox.serviceConfig = {
    EnvironmentFile = config.sops.templates."homebox.env".path;
    ExecStartPre = lib.mkBefore [
      (pkgs.writeShellScript "wait-for-postgres" ''
        set -euo pipefail

        while ! ${machine_config_psql.services.postgresql.package}/bin/pg_isready -h "psql.${const.domain}" -p 5432; do
          echo "Waiting for PostgreSQL to become available..."
          sleep 2
        done
        echo "PostgreSQL is ready! Starting HomeBox."
      '')
    ];
  };

  services.homebox = {
    enable = true;
    # Ref: https://homebox.software/en/quick-start/configure/
    settings = {
      # The types forces string value
      HBOX_WEB_PORT = "7745";

      HBOX_DATABASE_DRIVER = "postgres";
      # Unix socket if psql is on the same machines
      HBOX_DATABASE_HOST = if hostname == hostname_psql then "/run/postgresql" else "psql.${const.domain}";
      HBOX_DATABASE_USERNAME = "homebox";
      HBOX_DATABASE_DATABASE = "homebox";
      HBOX_DATABASE_PORT = toString config.services.postgresql.settings.port;

      HBOX_OIDC_ENABLED = "true";
      HBOX_OIDC_ISSUER_URL = "https://auth.${const.domain}";
      HBOX_OIDC_CLIENT_ID = "homebox";
      HBOX_OIDC_SCOPE = "openid profile email groups";
      HBOX_OIDC_AUTO_REDIRECT = "true";
      HBOX_OPTIONS_ALLOW_LOCAL_LOGIN = "false"; # Disable local credentials
      HBOX_OPTIONS_TRUST_PROXY = "true"; # Since I use traefik
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.homebox = {
      rule = "Host(`homebox.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "homebox";
      tls = { };
    };
    services.homebox.loadBalancer.servers = lib.singleton {
      url = "http://127.0.0.1:${config.services.homebox.settings.HBOX_WEB_PORT}";
    };
  };
}

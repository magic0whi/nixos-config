{
  const,
  pkgs,
  config,
  mylib,
  lib,
  ...
}:
{
  sops =
    let
      restartUnits = [ "grafana.service" ];
    in
    {
      secrets = {
        grafana_oauth_client_secret = {
          sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
          inherit restartUnits;
        };
        grafana_db_password = {
          sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
          inherit restartUnits;
        };
        grafana_secret_key = {
          sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
          inherit restartUnits;
        };
      };
      templates."grafana.env" = {
        content = mylib.toEnv {
          GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = config.sops.placeholder.grafana_oauth_client_secret;
          GRAFANA_DB_PASSWORD = config.sops.placeholder.grafana_db_password;
          GRAFANA_SECRET_KEY = config.sops.placeholder.grafana_secret_key;
        };
        inherit restartUnits;
      };
    };

  services.grafana = {
    enable = true;

    declarativePlugins = with pkgs.grafanaPlugins; [ yesoreyeram-infinity-datasource ];

    # https://grafana.com/docs/grafana/v13.1/setup-grafana/configure-grafana/
    settings = {
      server = {
        # protocol = "h2";
        domain = "grafana.${const.domain}";
        root_url = "https://grafana.${const.domain}"; # For OAuth callback
        http_port = 3001;
      };
      log = {
        mode = "syslog"; # default is "console" and "file"
        level = "error";
      };
      database = {
        type = "postgres";
        host = "/run/postgresql";
        user = "grafana";
        password = "$__env{GRAFANA_DB_PASSWORD}";
      };
      security.secret_key = "$__env{GRAFANA_SECRET_KEY}";
      auth.oauth_auto_login = true;
      "auth.anonymous".enabled = false;
      # https://grafana.com/docs/grafana/v13.1/setup-grafana/configure-access/configure-authentication/generic-oauth/
      "auth.generic_oauth" = {
        enabled = true;
        name = "Authelia";
        client_id = "grafana";
        scopes = "openid profile email groups";
        auth_url = "https://auth.${const.domain}/api/oidc/authorization";
        token_url = "https://auth.${const.domain}/api/oidc/token";
        api_url = "https://auth.${const.domain}/api/oidc/userinfo";
        login_attribute_path = "preferred_username";
        groups_attribute_path = "groups";
        name_attribute_path = "name";
        use_pkce = true;
        role_attribute_path = "contains(groups[*], 'admins') && 'Admin' || 'Viewer'";
        allow_sign_up = true; # NOTE: only enable for first time
      };
    };
  };

  systemd.services.grafana.serviceConfig.EnvironmentFile = config.sops.templates."grafana.env".path;

  services.traefik.dynamicConfigOptions.http = {
    routers.grafana = {
      rule = "Host(`grafana.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "grafana";
      tls = { };
    };
    services.grafana.loadBalancer.servers = lib.singleton {
      url = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
    };
  };
}

{
  const,
  pkgs,
  config,
  mylib,
  lib,
  ...
}:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "grafana" ];
        AAAA = [ "grafana" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
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
        grafana_ldap_password = {
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
          GRAFANA_LDAP_PASSWORD = config.sops.placeholder.grafana_ldap_password;
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
        password = "$__env{GRAFANA_LDAP_PASSWORD}";
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
        role_attribute_path = "contains(groups[*], 'admins') && 'Admin'"; # Will fallback to 'Viewer'
        allow_sign_up = true; # NOTE: only enable for first time
      };
    };
    # Declarative configuration
    provision = {
      enable = true;
      # https://grafana.com/docs/grafana/latest/administration/provisioning/#dashboards
      dashboards.settings.providers = lib.singleton {
        name = "Proteus' Homelab";
        disableDeletion = true;
        updateIntervalSeconds = 20;
        allowUiUpdates = false;
        options = {
          path = "${const.storagePath}/grafana/dashboards";
          # use folder structure from filesystem to create same folders in Grafana menu
          foldersFromFilesStructure = true;
        };
      };
      # Declaratively provision Grafana's data sources, dashboards, and alerting rules.
      # https://grafana.com/docs/grafana/latest/administration/provisioning/#data-sources
      datasources.settings = {
        # Note: removing attributes from the `datasources.settings.datasources` is not currently enough for them to be deleted;
        # List of data sources to delete from the database.
        # deleteDatasources = lib.singleton {
        #   name = "Loki";
        #   orgId = 1;
        # };

        # Mark provisioned data sources for deletion if they are no longer in a provisioning file.
        # It takes no effect if data sources are already listed in the deleteDatasources section.
        prune = true;

        datasources = [
          {
            # https://grafana.com/docs/grafana/latest/datasources/prometheus/configure/
            name = "prometheus-homelab";
            type = "prometheus";
            access = "proxy"; # proxy (request through grafana server) or direct (through users' browser).
            url = "https://prometheus.${const.domain}";
            basicAuth = true;
            basicAuthUser = "grafana";
            secureJsonData.basicAuthPassword = "$__env{GRAFANA_LDAP_PASSWORD}";
            jsonData = {
              httpMethod = "POST";
              manageAlerts = true;
              timeInterval = "15s";
              queryTimeout = "90s";
              prometheusType = "Prometheus";
              cacheLevel = "High";
              disableRecordingRules = false;
              # As of Grafana 10 the Prometheus data source can be configured to query live dashboards
              # incrementally instead of re-querying the entire duration on each dashboard refresh.
              # Increasing the duration of the incrementalQueryOverlapWindow will increase the size of every incremental query
              # but might be helpful for instances that have inconsistent results for recent data.
              incrementalQueryOverlapWindow = "10m";
            };
            # editable = true;
          }
          # Grafana's alerting rules is not recommended to use, we use Prometheus alertmanager instead.
          # TODO
          # {
          #   name = "alertmanager-homelab";
          #   type = "alertmanager";
          #   url = "http://localhost:9093";
          #   access = "proxy";
          #   jsonData = {
          #     implementation = "prometheus";
          #     handleGrafanaManagedAlerts = false;
          #   };
          #   editable = false;
          # }
          {
            # https://grafana.com/docs/grafana/latest/datasources/postgres/configure/
            name = "postgres-playground";
            type = "postgres";
            url = "postgresql.${const.domain}:5432";
            user = "grafana";
            secureJsonData.password = "$__env{GRAFANA_LDAP_PASSWORD}";
            jsonData = {
              database = "playground";
              sslmode = "verify-full"; # require/verify-ca/verify-full
              maxOpenConns = 50; # default 100
              maxIdleConns = 250; # default 100
              # maxIdleConnsAuto = true; # default true
              # connMaxLifetime = 4 * 60 * 60; # In seconds, default 14400 (4 hrs)
              timeInterval = "1m"; # Grafana recommends aligning this setting with the data write frequency.
              timescaledb = false; # A time-series database built as a PostgreSQL extensio
              postgresVersion = 1710; # 17.10
              # tls
              tlsConfigurationMethod = "file-path";
              sslRootCertFile = "${const.secretsDir}/proteus_ca.pub.pem";
            };
            # editable = true;
          }
          {
            name = "infinity-dataviewer";
            type = "yesoreyeram-infinity-datasource";
            # editable = true;
          }
        ];
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

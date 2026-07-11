{
  config,
  const,
  lib,
  machineConfigs,
  ...
}:
{
  sops.secrets =
    let
      owner = "prometheus";
    in
    {
      prometheus_bearer_token = { inherit owner; };
      prometheus_password = {
        sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
        inherit owner;
      };
    };

  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "prometheus" ];
        AAAA = [ "prometheus" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  services.prometheus = {
    enable = true;
    enableReload = true;
    port = 9093;
    listenAddress = "127.0.0.1";
    webExternalUrl = "https://prometheus.${const.domain}";
    checkConfig = "syntax-only"; # secrets will not be visible to promtool

    extraFlags = [
      "--storage.tsdb.retention.time=365d"
      "--storage.tsdb.retention.size=10GB"
    ];
    # https://prometheus.io/docs/prometheus/3.13/configuration/configuration/
    scrapeConfigs =
      let
        # [ "config" "services" "garage" "enable" ]
        mk_scrape' =
          {
            name,
            target ? hostname: "${name}-${hostname}.exporter.${const.domain}",
            attr_path ? [
              "config"
              "services"
              "prometheus"
              "exporters"
              "${name}"
              "enable"
            ],
            auth_cfg ? {
              basic_auth = {
                username = "prometheus";
                password_file = config.sops.secrets.prometheus_password.path;
              };
            },
          }:
          {
            job_name = name;
            scheme = "https";
            static_configs = lib.singleton {
              targets =
                map
                  (
                    hostname:
                    "${target hostname}${
                      machineConfigs.${hostname}.config.services.traefik.staticConfigOptions.entryPoints.websecure.address
                    }"
                  )
                  (
                    builtins.filter (hostname: lib.attrByPath attr_path false machineConfigs.${hostname}) (
                      builtins.attrNames machineConfigs
                    )
                  );
            };
          }
          // auth_cfg;
        mk_scrape = name: mk_scrape' { inherit name; };
      in
      map mk_scrape [
        "node"
        "systemd"
        "restic"
      ]
      ++ lib.singleton (mk_scrape' {
        name = "garage";
        target = hostname: "admin-api-${hostname}.garage.${const.domain}";
        attr_path = [
          "config"
          "services"
          "garage"
          "enable"
        ];
        auth_cfg.authorization = {
          type = "Bearer";
          credentials_file = config.sops.secrets.prometheus_bearer_token.path;
        };
      });
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.prometheus = {
      rule = "Host(`prometheus.${const.domain}`)";
      entryPoints = [ "websecure" ];
      middlewares = [ "authelia-auth" ];
      service = "prometheus";
      tls = { };
    };
    services.prometheus.loadBalancer.servers = lib.singleton {
      url = "http://127.0.0.1:${toString config.services.prometheus.port}";
    };
  };
}

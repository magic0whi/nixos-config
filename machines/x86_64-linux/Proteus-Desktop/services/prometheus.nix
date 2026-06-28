{
  config,
  const,
  lib,
  machineConfigs,
  ...
}:
{
  sops.secrets.prometheus_ldap_password = {
    sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
    key = "grafana_ldap_password";
    owner = "prometheus";
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
    scrapeConfigs =
      let
        mk_scrape = exporter_name: {
          job_name = exporter_name;
          scheme = "https";
          static_configs = lib.singleton {
            targets = map (hostname: "${exporter_name}-${hostname}.exporter.${const.domain}") (
              builtins.filter (
                hostname: machineConfigs.${hostname}.config.services.prometheus.exporters.${exporter_name}.enable or false
              ) (builtins.attrNames machineConfigs)
            );
          };
          basic_auth = {
            username = "grafana";
            password_file = config.sops.secrets.prometheus_ldap_password.path;
          };
        };
      in
      map mk_scrape [
        "node"
        "systemd"
      ]
      ++ [ (mk_scrape "restic") ];
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

{
  config,
  const,
  lib,
  ...
}:
{
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
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [ { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ]; } ];
      }
      {
        job_name = "systemd";
        static_configs = [ { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.systemd.port}" ]; } ];
      }
      # {
      #   job_name = "restic";
      #   static_configs = [ { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.restic.port}" ]; } ];
      # }
    ];
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

{ config, const, ... }:
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
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.prometheus = {
      rule = "Host(`prometheus.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "prometheus";
      tls = { };
    };
    services.prometheus.loadBalancer.servers = [
      { url = "http://127.0.0.1:${toString config.services.prometheus.port}"; }
    ];
  };
}

{
  const,
  config,
  lib,
  ...
}:
let
  hostname = config.networking.hostName;
  exporter_list = [
    "systemd"
    "node"
  ];
in
{
  vars =
    let
      # NOTE: bind doesn't allow underscore `_` in domain
      subs = map (name: "${name}-${hostname}.exporter") exporter_list;
    in
    {
      hostAddrs.${hostname}.easytier.subdomains = {
        A = subs;
        AAAA = subs;
      };
      forwardAuthServices = subs;
    };

  services.prometheus.exporters = lib.mkMerge (
    (map (exporter_name: {
      ${exporter_name} = {
        enable = true;
        listenAddress = "127.0.0.1";
      };
    }) exporter_list)
    ++ lib.singleton {
      # https://github.com/prometheus/node_exporter#collectors
      node.enabledCollectors = [
        "systemd"
        "netdev"
      ];
    }
  );

  services.traefik.dynamicConfigOptions.http = lib.mkMerge (
    map (name: {
      routers."prometheus-exporter_${name}" = {
        rule = "Host(`${name}-${hostname}.exporter.${const.domain}`)";
        entryPoints = [ "websecure" ];
        middlewares = [ "authelia-auth" ];
        service = "prometheus-exporter_${name}";
        tls = { };
      };
      services."prometheus-exporter_${name}".loadBalancer.servers = lib.singleton {
        url = "http://127.0.0.1:${toString config.services.prometheus.exporters.${name}.port}";
      };
    }) exporter_list
  );
}

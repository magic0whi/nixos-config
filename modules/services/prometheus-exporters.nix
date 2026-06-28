{
  const,
  config,
  lib,
  ...
}:
let
  hostname = config.networking.hostName;
  exporter_list = [
    "node"
    "systemd"
  ];
in
{
  services.prometheus.exporters = lib.mkMerge (
    (map (exporter_name: { ${exporter_name}.enable = true; }) exporter_list)
    ++ lib.singleton {
      # https://github.com/prometheus/node_exporter#collectors
      node.enabledCollectors = [
        "systemd"
        "netdev"
      ];
      # TODO
      # restic = {
      #   enable = true;
      #   # Restic exporter requires either a repository or repositoryFile to be set [file:2]
      #   repository = "s3:https://s3.example.com/bucket";
      #   # passwordFile = "/path/to/restic/password";
      # };
    }
  );

  services.traefik.dynamicConfigOptions.http = lib.mkMerge (
    map (name: {
      routers."prometheus-exporter-${name}" = {
        rule = "Host(`${name}-${hostname}.exporter.${const.domain}`)";
        entryPoints = [ "websecure" ];
        middlewares = [ "authelia-auth" ];
        service = "prometheus-exporter-${name}";
        tls = { };
      };
      services."prometheus-exporter-${name}".loadBalancer.servers = lib.singleton {
        url = "http://127.0.0.1:${toString config.services.prometheus.exporters.${name}.port}";
      };
    }) exporter_list
  );

  vars.hostAddrs.${hostname} = lib.mkMerge (
    map
      (nic_name: {
        ${nic_name}.subdomains =
          let
            subs = map (name: "${name}-${hostname}.exporter") exporter_list;
          in
          {
            A = subs;
            AAAA = subs;
          };
      })
      [
        "tailscale"
        "easytier"
      ]
  );
}

{
  const,
  config,
  lib,
  ...
}:
let
  # TODO
  hosts = [
    "Proteus-Desktop"
    "Proteus-NUC"
  ];
  exporters_cfg = {
    node = {
      enable = true;
      # https://github.com/prometheus/node_exporter#collectors
      enabledCollectors = [
        "systemd"
        "netdev"
      ];
    };
    systemd.enable = true;
    # restic = {
    #   enable = true;
    #   # Restic exporter requires either a repository or repositoryFile to be set [file:2]
    #   repository = "s3:https://s3.example.com/bucket";
    #   # passwordFile = "/path/to/restic/password";
    # };
  };
in
{
  services.prometheus.exporters = exporters_cfg;

  services.traefik.dynamicConfigOptions.http = lib.mkMerge (
    map
      (name: {
        routers."prometheus-exporter-${name}" = {
          rule = "Host(`prometheus-${name}-${config.networking.hostName}.${const.domain}`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "authelia-auth" ];
          service = "prometheus-exporter-${name}";
          tls = { };
        };
        services."prometheus-exporter-${name}".loadBalancer.servers = lib.singleton {
          url = "http://127.0.0.1:${toString config.services.prometheus.exporters.${name}.port}";
        };
      })
      [
        "node"
        "systemd"
      ]
  );

  vars.hostAddrs = lib.mkMerge (
    map (hostname: {
      ${hostname} = lib.mkMerge (
        map
          (nic_name: {
            ${nic_name}.subdomains =
              let
                subs = map (name: "prometheus-exporter-${name}-${hostname}") (
                  builtins.filter (exporter_name: exporters_cfg.${exporter_name}.enable) (builtins.attrNames exporters_cfg)
                );
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
    }) hosts
  );
}

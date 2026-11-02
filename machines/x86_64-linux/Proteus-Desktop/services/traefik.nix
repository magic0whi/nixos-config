{
  const,
  config,
  lib,
  ...
}:
let
  hostname = config.networking.hostName;
in
{
  vars =
    let
      subs = [ "${hostname}.sb" ];
    in
    {
      hostAddrs.${config.networking.hostName}.easytier.subdomains = {
        A = subs;
        AAAA = subs;
      };
      forwardAuthServices = subs;
    };

  services.traefik = {
    dynamicConfigOptions.http = {
      routers.sb-dashboard = {
        rule = "Host(`${hostname}.sb.${const.domain}`)";
        entryPoints = [ "websecure" ];
        middlewares = [ "authelia-auth" ];
        service = "sb-dashboard";
        tls = { };
      };
      services.sb-dashboard.loadBalancer.servers = lib.singleton {
        url = "http://${config.services.sing-box.settings.experimental.clash_api.external_controller or "127.0.0.1:9091"}";
      };
    };
  };
}

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
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains =
        let
          subs = [
            "${hostname}.traefik"
            "${hostname}.sb"
          ];
        in
        {
          A = subs;
          AAAA = subs;
        };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  services.traefik = {
    dynamicConfigOptions.http = {
      routers = {
        traefik-dashboard.rule = "Host(`${hostname}.traefik.${const.domain}`)";
        qinglong = {
          rule = "Host(`ql.${const.domain}`)";
          entryPoints = [ "websecure" ];
          service = "qinglong";
          tls = { };
        };
        sb-dashboard = {
          rule = "Host(`${hostname}.sb.${const.domain}`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "authelia-auth" ];
          service = "sb-dashboard";
          tls = { };
        };
      };
      services = {
        qinglong.loadBalancer.servers = [ { url = "http://127.0.0.1:5700"; } ];
        sb-dashboard.loadBalancer.servers = lib.singleton {
          url = "http://${config.services.sing-box.settings.experimental.clash_api.external_controller or "127.0.0.1:9091"}";
        };
      };
    };
  };
}

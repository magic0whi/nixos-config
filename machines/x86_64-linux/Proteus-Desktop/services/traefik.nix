{
  const,
  ...
}:
{
  services.traefik = {
    dynamicConfigOptions.http = {
      routers = {
        traefik-dashboard.rule = "Host(`traefik-desktop.${const.domain}`)";
        qinglong = {
          rule = "Host(`ql.${const.domain}`)";
          entryPoints = [ "websecure" ];
          service = "qinglong";
          tls = { };
        };
        sb = {
          rule = "Host(`sb-desktop.${const.domain}`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "authelia-auth" ];
          service = "sb-dashboard";
          tls = { };
        };
        papra = {
          rule = "Host(`papra.${const.domain}`)";
          entryPoints = [ "websecure" ];
          service = "papra";
          tls = { };
        };
        plane = {
          rule = "Host(`plane.${const.domain}`)";
          entryPoints = [ "websecure" ];
          service = "plane";
          tls = { };
        };
      };
      services = {
        qinglong.loadBalancer.servers = [ { url = "http://127.0.0.1:5700"; } ];
        sb-dashboard.loadBalancer.servers = [ { url = "http://127.0.0.1:9091"; } ];
        papra.loadBalancer.servers = [ { url = "http://127.0.0.1:1221"; } ];
        plane.loadBalancer.servers = [ { url = "http://127.0.0.1:8082"; } ];
      };
    };
  };
}

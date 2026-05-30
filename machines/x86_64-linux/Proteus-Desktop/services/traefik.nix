{
  myvars,
  ...
}:
{
  services.traefik = {
    dynamicConfigOptions.http = {
      routers = {
        traefik-dashboard.rule = "Host(`traefik-desktop.${myvars.domain}`)";
        qinglong = {
          rule = "Host(`ql.${myvars.domain}`)";
          entryPoints = [ "websecure" ];
          service = "qinglong";
          tls = { };
        };
        sb = {
          rule = "Host(`sb-desktop.${myvars.domain}`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "authelia-auth" ];
          service = "sb-dashboard";
          tls = { };
        };
        papra = {
          rule = "Host(`papra.${myvars.domain}`)";
          entryPoints = [ "websecure" ];
          service = "papra";
          tls = { };
        };
        plane = {
          rule = "Host(`plane.${myvars.domain}`)";
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

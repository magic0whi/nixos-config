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
      };
      services = {
        qinglong.loadBalancer.servers = [ { url = "http://127.0.0.1:5700"; } ];
        sb-dashboard.loadBalancer.servers = [ { url = "http://127.0.0.1:9091"; } ];
      };
    };
  };
}

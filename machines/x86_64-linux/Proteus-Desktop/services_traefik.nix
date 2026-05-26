{
  myvars,
  ...
}:
{
  services.traefik = {
    dynamicConfigOptions.http = {
      routers = {
        traefik-dashboard.rule = "Host(`traefik-desktop.${myvars.domain}`)";
        sb = {
          rule = "Host(`sb-desktop.${myvars.domain}`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "authelia-auth" ];
          service = "sb-dashboard";
          tls = { };
        };
      };
      services.sb-dashboard.loadBalancer.servers = [ { url = "http://127.0.0.1:9091"; } ];
    };
  };
}

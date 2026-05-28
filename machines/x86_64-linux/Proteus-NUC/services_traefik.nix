{
  config,
  myvars,
  ...
}:
{
  services.traefik = {
    dynamicConfigOptions.http = {
      routers = {
        traefik-dashboard.rule = "Host(`traefik-nuc.${myvars.domain}`)";
        syncthing = {
          rule = "Host(`syncthing-nuc.${myvars.domain}`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "authelia-auth" ];
          service = "syncthing-dashboard";
          tls = { };
        };
        sb = {
          rule = "Host(`sb-nuc.${myvars.domain}`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "authelia-auth" ];
          service = "sb-dashboard";
          tls = { };
        };
      };
      services = {
        sb-dashboard.loadBalancer.servers = [ { url = "http://127.0.0.1:9091"; } ];
        syncthing-dashboard.loadBalancer = {
          # By setting to false Traefik will overrides the Host header to
          # 127.0.0.1
          passHostHeader = false;
          servers = [ { url = "http://${config.home-manager.users.${myvars.username}.services.syncthing.guiAddress}"; } ];
          healthCheck.path = "/rest/noauth/health";
        };
      };
    };
  };
}

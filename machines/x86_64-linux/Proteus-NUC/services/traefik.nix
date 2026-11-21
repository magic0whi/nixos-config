{
  config,
  const,
  ...
}:
let
  hostname = config.networking.hostName;
  sub = "${hostname}.syncthing";
in
{
  vars = {
    hostAddrs.${config.networking.hostName}.easytier.subdomains = {
      A = [ sub ];
      AAAA = [ sub ];
    };
    forwardAuthServices = [ sub ];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers = {
      syncthing = {
        rule = "Host(`${sub}.${const.domain}`)";
        entryPoints = [ "websecure" ];
        middlewares = [ "authelia-auth" ];
        service = "syncthing-dashboard";
        tls = { };
      };
    };
    services.syncthing-dashboard.loadBalancer = {
      # By setting to false, Traefik will overrides the Host header to 127.0.0.1
      passHostHeader = false;
      servers = [ { url = "http://${config.home-manager.users.${const.username}.services.syncthing.guiAddress}"; } ];
      healthCheck.path = "/rest/noauth/health";
    };
  };
}

{
  config,
  const,
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
            "${hostname}.syncthing"
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
        syncthing = {
          rule = "Host(`${hostname}.syncthing.${const.domain}`)";
          entryPoints = [ "websecure" ];
          # TODO, security: all services accounts in LDAP allows access to authelia-auth
          middlewares = [ "authelia-auth" ];
          service = "syncthing-dashboard";
          tls = { };
        };
        sb = {
          rule = "Host(`${hostname}.sb.${const.domain}`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "authelia-auth" ];
          service = "sb-dashboard";
          tls = { };
        };
      };
      services = {
        sb-dashboard.loadBalancer.servers = lib.singleton {
          url = "http://${config.services.sing-box.settings.experimental.clash_api.external_controller or "127.0.0.1:9091"}";
        };
        syncthing-dashboard.loadBalancer = {
          # By setting to false Traefik will overrides the Host header to
          # 127.0.0.1
          passHostHeader = false;
          servers = [ { url = "http://${config.home-manager.users.${const.username}.services.syncthing.guiAddress}"; } ];
          healthCheck.path = "/rest/noauth/health";
        };
      };
    };
  };
}

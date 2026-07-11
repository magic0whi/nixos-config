{
  config,
  const,
  ...
}:
let
  hostname = config.networking.hostName;
in
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "${hostname}.syncthing" ];
        AAAA = [ "${hostname}.syncthing" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  services.traefik.dynamicConfigOptions.http = {
    routers.syncthing = {
      rule = "Host(`${hostname}.syncthing.${const.domain}`)";
      entryPoints = [ "websecure" ];
      middlewares = [ "authelia-auth" ];
      service = "syncthing-dashboard";
      tls = { };
    };
    services.syncthing-dashboard.loadBalancer = {
      passHostHeader = false;
      servers = [ { url = "http://${config.services.syncthing.guiAddress}"; } ];
      healthCheck.path = "/rest/noauth/health";
    };
  };

  imports = [ const.syncthing ];

  systemd.services.syncthing.unitConfig.RequiresMountsFor = [ const.storagePath ];
  services.syncthing = {
    settings.folders =
      let
        prefix = "${const.storagePath}/share";
      in
      {
        Documents.path = "${prefix}/Documents";
        Games.path = "${prefix}/Games";
        KeePassXC.path = "${prefix}/KeePassXC";
        Pictures.path = "${prefix}/Pictures";
        Projects.path = "${prefix}/Projects";
      };
  };
}

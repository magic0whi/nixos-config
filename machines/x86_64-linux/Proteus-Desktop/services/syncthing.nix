{
  config,
  const,
  mylib,
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

  imports = [ (mylib.relativeToRoot "const/syncthing.nix") ];

  systemd.services.syncthing.unitConfig.RequiresMountsFor = [ const.storagePath ];
  services.syncthing = {
    settings.folders = {
      Documents.path = "${const.storagePath}/share/Documents";
      Games.path = "${const.storagePath}/share/Games";
      KeePassXC.path = "${const.storagePath}/share/KeePassXC";
      Pictures.path = "${const.storagePath}/share/Pictures";
      Projects.path = "${const.storagePath}/share/Projects";
      nix-darwin.path = "${const.storagePath}/nix-darwin";
    };
  };
}

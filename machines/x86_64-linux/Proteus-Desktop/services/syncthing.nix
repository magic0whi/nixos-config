{
  config,
  const,
  mylib,
  ...
}:
{
  imports = [ (mylib.relativeToRoot "const/syncthing.nix") ];

  systemd.services.syncthing.unitConfig.RequiresMountsFor = [ const.storagePath ];
  services.syncthing = {
    settings.folders = {
      Documents.path = "${const.storagePath}/share/Documents";
      Games.path = "${const.storagePath}/share/Games";
      KeePassXC.path = "${const.storagePath}/share/KeePassXC";
      Music.path = "${const.storagePath}/share/Music";
      Pictures.path = "${const.storagePath}/share/Pictures";
      Works.path = "${const.storagePath}/share/Works";
      nix-darwin.path = "${const.storagePath}/nix-darwin";
    };
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.syncthing = {
      rule = "Host(`syncthing-desktop.${const.domain}`)";
      entryPoints = [ "websecure" ];
      middlewares = [ "authelia-auth" ];
      service = "syncthing-dashboard";
      tls = { };
    };
    services.syncthing-dashboard.loadBalancer = {
      passHostHeader = false;
      servers = [ { url = "http://${config.home-manager.users.${const.username}.services.syncthing.guiAddress}"; } ];
      healthCheck.path = "/rest/noauth/health";
    };
  };
}

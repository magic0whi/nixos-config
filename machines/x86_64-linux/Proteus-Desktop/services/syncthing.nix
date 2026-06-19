{
  config,
  lib,
  const,
  ...
}:
{
  sops.secrets."${config.networking.hostName}_syncthing.priv.pem" = {
    sopsFile = "${const.secretsDir}/${config.networking.hostName}_syncthing.priv.pem.sops";
    format = "binary";
    restartUnits = [ "syncthing.service" ];
  };

  # If without `users.groups.storage` and rely on LDAP group
  # systemd.services.syncthing.serviceConfig.SupplementaryGroups = ["storage"];

  systemd.services.syncthing.unitConfig.RequiresMountsFor = [ const.storagePath ];
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    group = "storage"; # Don't work for a LDAP group
    key = config.sops.secrets."${config.networking.hostName}_syncthing.priv.pem".path;
    cert = "${const.secretsDir}/${config.networking.hostName}_syncthing.pub.pem";
    settings =
      let
        mobile_devices = {
          "LGE-AN00".id = "T2V6DJB-243NJGD-5B63LUP-DSLNFBD-U72KGD2-AZVTIHL-HEUMBTI-HAVD7A2";
          "M2011K2C".id = "W6ZP2GU-HJ5DM7Q-UXKEKCI-OL3TYHM-LGLLPIN-3MCH7DM-76K3DB5-KNELIA5";
          "Redmi Note 5".id = "V3BFX3M-H4RJSCS-DZ6XQIM-3T5JK2V-KPYKGPD-HUV5UMG-PQA52BH-MYOFIAR";
        };
      in
      {
        # Import all known hosts that has attr `syncthing_id` but filter out self
        devices =
          mobile_devices
          // (builtins.mapAttrs (_: v: { id = v.syncthing_id; }) (
            lib.filterAttrs (n: v: v ? syncthing_id && n != config.networking.hostName) const.networking.knownHosts
          ));
        folders = {
          "Documents" = {
            path = "${const.storagePath}/share/Documents";
            devices = builtins.attrNames config.services.syncthing.settings.devices; # All devices
          };
          "Games" = {
            path = "${const.storagePath}/share/Games";
            devices = lib.subtractLists (builtins.attrNames mobile_devices) (
              builtins.attrNames config.services.syncthing.settings.devices
            );
          };
          "KeePassXC" = {
            path = "${const.storagePath}/share/KeePassXC";
            devices = builtins.attrNames config.services.syncthing.settings.devices;
          };
          "Music" = {
            path = "${const.storagePath}/share/Music";
            devices = builtins.attrNames config.services.syncthing.settings.devices;
          };
          "Pictures" = {
            path = "${const.storagePath}/share/Pictures";
            devices = builtins.attrNames config.services.syncthing.settings.devices;
          };
          "Works" = {
            path = "${const.storagePath}/share/Works";
            devices = lib.subtractLists (builtins.attrNames mobile_devices) (
              builtins.attrNames config.services.syncthing.settings.devices
            );
          };
        };
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

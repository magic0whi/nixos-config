{
  config,
  lib,
  myvars,
  osConfig,
  ...
}:
{
  sops.secrets."${osConfig.networking.hostName}_syncthing.priv.pem" = {
    sopsFile = "${myvars.secrets_dir}/${osConfig.networking.hostName}_syncthing.priv.pem.sops";
    format = "binary";
  };
  services.syncthing = {
    key = config.sops.secrets."${osConfig.networking.hostName}_syncthing.priv.pem".path;
    cert = "${myvars.secrets_dir}/${osConfig.networking.hostName}_syncthing.pub.pem";
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
            lib.filterAttrs (n: v: v ? syncthing_id && n != osConfig.networking.hostName) myvars.networking.known_hosts
          ));
        folders = {
          "Documents" = {
            path = config.xdg.userDirs.documents;
            # All devices
            devices = builtins.attrNames config.services.syncthing.settings.devices;
          };
          "Games" = {
            path = "${config.home.homeDirectory}/Games";
            # Include all but exclude mobile devices
            devices = lib.subtractLists (builtins.attrNames mobile_devices) (
              builtins.attrNames config.services.syncthing.settings.devices
            );
          };
          "Music" = {
            path = config.xdg.userDirs.music;
            devices = builtins.attrNames config.services.syncthing.settings.devices;
          };
          "Pictures" = {
            path = config.xdg.userDirs.pictures;
            devices = builtins.attrNames config.services.syncthing.settings.devices;
          };
          "Secrets" = {
            path = "${config.home.homeDirectory}/Secrets";
            devices = lib.subtractLists (builtins.attrNames mobile_devices) (
              builtins.attrNames config.services.syncthing.settings.devices
            );
          };
          "Works" = {
            path = "${config.home.homeDirectory}/Works";
            devices = lib.subtractLists (builtins.attrNames mobile_devices) (
              builtins.attrNames config.services.syncthing.settings.devices
            );
          };
        };
      };
  };
}

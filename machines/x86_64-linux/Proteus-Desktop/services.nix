{
  myvars,
  config,
  lib,
  # mylib,
  ...
}:
{
  ## BEGIN services_monero.nix
  systemd.services.monero.unitConfig.RequiresMountsFor = [ myvars.storage_path ];
  services.monero = {
    enable = true;
    dataDir = "${myvars.storage_path}/monero";
    extraConfig = ''
      # log-file=${config.services.monero.dataDir}/monero.log
      # log-level=0
      p2p-use-ipv6=1
      rpc-use-ipv6=1
      public-node=1
      confirm-external-bind=1
      rpc-bind-ipv6-address=fd7a:115c:a1e0::d901:e013
    '';
    prune = true;
    rpc.address = "0.0.0.0";
    rpc.restricted = true;
  };
  ## END services_monero.nix
  ## BEGIN syncthing.nix
  sops.secrets."${config.networking.hostName}_syncthing.priv.pem" = {
    sopsFile = "${myvars.secrets_dir}/${config.networking.hostName}_syncthing.priv.pem.sops";
    format = "binary";
    restartUnits = [ "syncthing.service" ];
  };
  # If without `users.groups.storage` and rely on LDAP group
  # systemd.services.syncthing.serviceConfig.SupplementaryGroups = ["storage"];
  systemd.services.syncthing.unitConfig.RequiresMountsFor = [ myvars.storage_path ];
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    group = "storage"; # Don't work for a LDAP group
    key = config.sops.secrets."${config.networking.hostName}_syncthing.priv.pem".path;
    cert = "${myvars.secrets_dir}/${config.networking.hostName}_syncthing.pub.pem";
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
          // (builtins.mapAttrs (n: v: { id = v.syncthing_id; }) (
            lib.filterAttrs (n: v: v ? syncthing_id && n != config.networking.hostName) myvars.networking.known_hosts
          ));
        folders = {
          "Documents" = {
            path = "${myvars.storage_path}/share/Documents";
            devices = builtins.attrNames config.services.syncthing.settings.devices; # All devices
          };
          "Games" = {
            path = "${myvars.storage_path}/share/Games";
            devices = lib.subtractLists (builtins.attrNames mobile_devices) (
              builtins.attrNames config.services.syncthing.settings.devices
            );
          };
          "Music" = {
            path = "${myvars.storage_path}/share/Music";
            devices = builtins.attrNames config.services.syncthing.settings.devices;
          };
          "Pictures" = {
            path = "${myvars.storage_path}/share/Pictures";
            devices = builtins.attrNames config.services.syncthing.settings.devices;
          };
          "Secrets" = {
            path = "${myvars.storage_path}/share/Secrets";
            devices = lib.subtractLists (builtins.attrNames mobile_devices) (
              builtins.attrNames config.services.syncthing.settings.devices
            );
          };
          "Works" = {
            path = "${myvars.storage_path}/share/Works";
            devices = lib.subtractLists (builtins.attrNames mobile_devices) (
              builtins.attrNames config.services.syncthing.settings.devices
            );
          };
        };
      };
  };
  ## END syncthing.nix
}

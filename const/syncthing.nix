# This files share between NixOS modules and Home Manager Modules
args@{
  config,
  lib,
  const,
  ...
}:
let
  osConfig = args.osConfig or { };
  hostname = osConfig.networking.hostName or config.networking.hostName;
  isNixOSModule = osConfig == { };

  device = rec {
    # Filter out self
    _desktops = {
      Proteus-MBP14M4P.id = "UF2KT6R-ISVDLBM-UJW3JKP-YZJTOES-7K55HS2-IGPE5MQ-OO4D6HK-LZRSLAE";
      Proteus-NUC.id = "3P2RWV6-RQMHBFS-L3Z5JTF-O6HOR66-7INJZNM-XW3WUSG-XCIB454-UITNPAF";
    };
    desktops = lib.filterAttrs (n: _: n != hostname) _desktops;
    servers = lib.filterAttrs (n: _: n != hostname) {
      Proteus-Desktop.id = "DFKVKXA-MHOUCDP-2DXEZGE-VUGGQXP-MRQCOZL-BOOBXAV-4IDSU26-B3GOUAF";
    };
    mobiles = {
      LGE-AN00.id = "T2V6DJB-243NJGD-5B63LUP-DSLNFBD-U72KGD2-AZVTIHL-HEUMBTI-HAVD7A2";
      M2011K2C.id = "W6ZP2GU-HJ5DM7Q-UXKEKCI-OL3TYHM-LGLLPIN-3MCH7DM-76K3DB5-KNELIA5";
      "Redmi Note 5".id = "V3BFX3M-H4RJSCS-DZ6XQIM-3T5JK2V-KPYKGPD-HUV5UMG-PQA52BH-MYOFIAR";
    };
  };

in
{
  sops.secrets."${hostname}_syncthing.priv.pem" = lib.mkMerge [
    (lib.optionalAttrs isNixOSModule { restartUnits = [ "syncthing.service" ]; })
    {
      sopsFile = "${const.secretsDir}/${hostname}_syncthing.priv.pem.sops";
      format = "binary"; # Required when loading raw files instead of yaml/json structures
      # sops-nix dnn't have restartUnits for home manager
      # https://github.com/ryantm/agenix/issues/84
      # restartUnits = ["syncthing-init.service" "syncthing.service"];
    }
  ];
  services.syncthing = lib.mkMerge [
    (lib.optionalAttrs isNixOSModule {
      openDefaultPorts = true;
      group = "storage"; # Not work for a LDAP group
    })
    {
      enable = true;
      # nix run nixpkgs#syncthing -- generate --config myconfig/"
      key = config.sops.secrets."${hostname}_syncthing.priv.pem".path;
      cert = "${const.secretsDir}/${hostname}_syncthing.pub.pem";
      settings = {
        devices = device.mobiles // device.desktops // device.servers;
        folders =
          let
            all = builtins.attrNames config.services.syncthing.settings.devices;
            desktops = builtins.attrNames device.desktops;
            servers = builtins.attrNames device.servers;

            prefix = "${config.home.homeDirectory}/Proteus";
          in
          lib.mkMerge [
            (lib.mkIf (!isNixOSModule) {
              Secrets = {
                path = lib.mkDefault "${prefix}/Secrets";
                devices = desktops;
              };
            })
            (lib.mkIf (builtins.elem hostname (builtins.attrNames device._desktops)) {
              Projects-Ref = {
                path = lib.mkDefault "${prefix}/Projects-Ref/";
                devices = desktops;
              };
            })
            {
              Documents = {
                path = lib.mkDefault "${prefix}/Documents";
                devices = all;
              };
              Games = {
                path = lib.mkDefault "${prefix}/Games";
                devices = desktops;
              };
              KeePassXC = {
                path = lib.mkDefault "${prefix}/KeePassXC";
                devices = all;
              };
              Pictures = {
                path = lib.mkDefault "${prefix}/Pictures";
                devices = all;
              };
              Projects = {
                path = lib.mkDefault "${prefix}/Projects";
                devices = desktops ++ servers;
              };
            }
          ];
      };
    }
  ];
}

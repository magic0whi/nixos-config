{
  config,
  lib,
  const,
  osConfig,
  ...
}:
{
  sops.secrets."${osConfig.networking.hostName}_syncthing.priv.pem" = {
    sopsFile = "${const.secretsDir}/${osConfig.networking.hostName}_syncthing.priv.pem.sops";
    format = "binary"; # Required when loading raw files instead of yaml/json structures
    # sops-nix dnn't have restartUnits for home manager
    # https://github.com/ryantm/agenix/issues/84
    # restartUnits = ["syncthing-init.service" "syncthing.service"];
  };
  services.syncthing = {
    # nix run nixpkgs#syncthing -- generate --config myconfig/"
    key = config.sops.secrets."${osConfig.networking.hostName}_syncthing.priv.pem".path;
    cert = "${const.secretsDir}/${osConfig.networking.hostName}_syncthing.pub.pem";
    settings = {
      devices =
        const.networking.syncthing.mobile
        // lib.filterAttrs (n: _: n != osConfig.networking.hostName) const.networking.syncthing.desktop;
      folders =
        let
          all = builtins.attrNames config.services.syncthing.settings.devices;
          except_mobile = lib.subtractLists (builtins.attrNames const.networking.syncthing.mobile) all;
          inherit (config.home) homeDirectory;
        in
        {
          "Documents" = {
            path = config.xdg.userDirs.documents;
            # All devices
            devices = all;
          };
          "Games" = {
            path = "${homeDirectory}/Games";
            devices = except_mobile;
          };
          "KeePassXC" = {
            path = "${homeDirectory}/KeePassXC";
            devices = all;
          };
          "Music" = {
            path = config.xdg.userDirs.music;
            devices = all;
          };
          "Pictures" = {
            path = config.xdg.userDirs.pictures;
            devices = all;
          };
          "Secrets" = {
            path = "${homeDirectory}/Secrets";
            devices = except_mobile;
          };
          "Works" = {
            path = "${homeDirectory}/Works";
            devices = except_mobile;
          };
          "nix-darwin" = {
            path = "${homeDirectory}/Works-References/nix-darwin";
            devices = except_mobile;
          };
        };
    };
  };
}

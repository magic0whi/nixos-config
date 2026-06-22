{
  config,
  lib,
  mylib,
  const,
  pkgs,
  ...
}:
let
  settingsFormat = pkgs.formats.json { };
in
{
  options.services.sing-box.generateMobileConfig = {
    enable = lib.mkEnableOption "Generate configs for mobile devices";
    mobile = lib.mkOption {
      type = lib.types.submodule { freeformType = settingsFormat.type; };
      readOnly = true;
      default = import (mylib.relativeToRoot "modules/common/_sing-box-client") {
        inherit
          config
          lib
          mylib
          const
          pkgs
          ;
        isDarwin = false;
        isLinux = false;
        isMobile = true;
      };
    };
    root = lib.mkOption {
      type = lib.types.submodule { freeformType = settingsFormat.type; };
      readOnly = true;
      default = import (mylib.relativeToRoot "modules/common/_sing-box-client") {
        inherit
          config
          lib
          mylib
          const
          pkgs
          ;
        isDarwin = false;
        isLinux = true;
        isMobile = true;
      };
    };
  };
  config =
    let
      cfg = config.services.sing-box.generateMobileConfig;
    in
    lib.mkIf cfg.enable {
      # TODO sing-box-subscribe
      systemd.services.sing-box.serviceConfig.ExecStartPre = [
        # Generate alter config.json for mobile devices
        "+-${
          let
            utils = import "${pkgs.path}/nixos/lib/utils.nix" { inherit config lib pkgs; };
          in
          pkgs.writeShellScript "gen-mobile-config" ''
            set -euo pipefail
            ${utils.genJqSecretsReplacementSnippet cfg.mobile "/run/secrets/mobile.json"}
            chown --reference=/run/sing-box /run/secrets/mobile.json
          ''
        }"
        # Generate alter config.json for rooted mobile devices
        "+-${
          let
            utils = import "${pkgs.path}/nixos/lib/utils.nix" { inherit config lib pkgs; };
          in
          pkgs.writeShellScript "gen-root-mobile-config" ''
            set -euo pipefail
            ${utils.genJqSecretsReplacementSnippet cfg.root "/run/secrets/root.json"}
            chown --reference=/run/sing-box /run/secrets/root.json
          ''
        }"
      ];
    };
}

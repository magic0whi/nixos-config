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
      # TIP: After provision you can manually process with sing-box-subscribe
      systemd.services.sing-box.serviceConfig.ExecStartPre = [
        # Generate alter config.json for mobile devices
        # NOTE: sing-box will treat all the *.json in the working directory as splitted config
        "+-${
          let
            utils = import "${pkgs.path}/nixos/lib/utils.nix" { inherit config lib pkgs; };
          in
          pkgs.writeShellScript "gen-mobile-config" ''
            set -euo pipefail
            mkdir -p /run/sing-box/modile
            ${utils.genJqSecretsReplacementSnippet cfg.mobile "/run/sing-box/mobile/mobile.json"}
            chown --reference=/run/sing-box /run/sing-box/mobile.json
          ''
        }"
        # Generate alter config.json for rooted mobile devices
        "+-${
          let
            utils = import "${pkgs.path}/nixos/lib/utils.nix" { inherit config lib pkgs; };
          in
          pkgs.writeShellScript "gen-root-mobile-config" ''
            set -euo pipefail
            mkdir -p /run/sing-box/modile
            ${utils.genJqSecretsReplacementSnippet cfg.root "/run/sing-box/mobile/root.json"}
            chown --reference=/run/sing-box /run/sing-box/root.json
          ''
        }"
      ];
    };
}

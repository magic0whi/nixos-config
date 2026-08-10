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
}

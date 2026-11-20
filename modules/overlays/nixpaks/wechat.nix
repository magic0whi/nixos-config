# Hardened WeChat.
#
# Upstream ships the native (non-FHS) Linux build now, so nixpak can be the
# only bubblewrap layer. The old `wechat-uos` package already runs inside an
# FHS sandbox, and wrapping that in bubblewrap again caused the breakage noted
# in the previous version of this file.
#
# Refer:
# - WeChat's flatpak manifest: https://github.com/flathub/com.tencent.WeChat
# - nixpkgs package: pkgs/by-name/we/wechat
{
  lib,
  wechat,
  mkNixPak,
  buildEnv,
  makeDesktopItem,
  runCommandLocal,
  ...
}:
let
  appId = "com.tencent.WeChat";

  wrapped = mkNixPak {
    config = {
      imports = [ ./modules/wechat-policy.nix ];
      app = {
        package = wechat;
        binPath = "bin/wechat";
      };
      flatpak = { inherit appId; };
    };
  };
  exe = lib.getExe wrapped.config.script;
  # Expose the hicolor theme so the app is still resolvable by icon name from
  # the profile, e.g. by tray and notification daemons.
  assets = runCommandLocal "wechat-desktop-assets" { } ''
    mkdir -p $out/share
    ln -s ${wechat}/share/icons $out/share/icons
  '';
in
buildEnv {
  inherit (wrapped.config.script) name passthru;
  meta = wrapped.config.script.meta // {
    mainProgram = "wechat";
  };
  paths = [
    wrapped.config.script
    assets
    (makeDesktopItem {
      name = "wechat";
      desktopName = "WeChat";
      exec = "${exe} %U";
      icon = "${wechat}/share/icons/hicolor/256x256/apps/wechat.png";
      terminal = false;
      startupWMClass = "wechat";
      categories = [
        "Network"
        "InstantMessaging"
      ];
      mimeTypes = [ "x-scheme-handler/weixin" ];
      # Lets the xdg-desktop-portal match the running app to this app ID, which
      # is what makes the file chooser/notification portals usable.
      extraConfig.X-Flatpak = appId;
    })
  ];
}

# WeChat data and its sandbox boundary are owned by nixpak.
{
  lib,
  pkgs,
  sloth,
  ...
}:
{
  imports = [
    ./desktop-base.nix
    ./network.nix
  ];
  pasta.mode = "isolate";
  desktopIntegration.tray = true;
  portalGroups = {
    fileChooser = true;
    openUri = true;
    notifications = true;
    screenCast = true;
    camera = true;
    inputMethod = true;
  };
  bubblewrap = {
    # Keep X11 available so a bad Wayland path can be worked around locally
    # with QT_QPA_PLATFORM=xcb; auto-detection still prefers Wayland.
    sockets.x11 = true;
    bind.rw = [
      # `mkdir` is what creates the directory on the host, so use the app data
      # dir as the source: xdg-storage maps <appDataDir> over $XDG_DATA_HOME, so
      # the destination below resolves to the same inode and this is a no-op
      # bind that only guarantees that the sandbox's $HOME exists on first run.
      [
        (sloth.mkdir (sloth.concat' sloth.appDataDir "/wechat"))
        (sloth.concat' sloth.xdgDataHome "/wechat")
      ]
      sloth.xdgDocumentsDir
      sloth.xdgDownloadDir
    ];
    env = {
      # WeChat keeps .xwechat and xwechat_files under HOME, so pointing HOME at
      # the private per-app data dir keeps all of its state in one place.
      # User-selected files also go through the XDG file chooser portal.
      HOME = lib.mkForce (sloth.concat' sloth.xdgDataHome "/wechat");
      DISPLAY = sloth.envOr "DISPLAY" "";
      XAUTHORITY = sloth.envOr "XAUTHORITY" (sloth.concat' sloth.homeDir "/.Xauthority");
      XDG_DOCUMENTS_DIR = sloth.xdgDocumentsDir;
      XDG_DOWNLOAD_DIR = sloth.xdgDownloadDir;
      PATH = lib.makeBinPath [ pkgs.coreutils ];
    };
  };
}

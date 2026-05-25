# https://github.com/nixpak/pkgs/blob/master/pkgs/modules/gui-base.nix
{
  config,
  lib,
  pkgs,
  sloth,
  ...
}:
let
  envSuffix = envKey: suffix: sloth.concat' (sloth.env envKey) suffix;
  # cursor & icon's theme should be the same as the host's one.
  cursor_theme = pkgs.bibata-cursors;
in
{
  config = {
    dbus.policies = {
      "${config.flatpak.appId}.*" = "own"; # A name of "org.foo.*" matches "org.foo", org.foo.bar", and "org.foo.bar.gazonk", but not "org.foobar".
      "org.freedesktop.DBus" = "talk";
      "org.gtk.vfs.*" = "talk";
      "ca.desrt.dconf" = "talk";
      "org.a11y.Bus" = "talk";
      "org.freedesktop.portal.*" = "talk";
      "org.freedesktop.Notifications" = "talk";
    };
    # https://github.com/nixpak/nixpak/blob/master/modules/gpu.nix
    # 1. bind readonly - /run/opengl-driver
    # 2. bind device   - /dev/dri
    gpu = {
      enable = lib.mkDefault true;
      provider = "nixos";
      bundlePackage = pkgs.mesa.drivers; # for amd & intel
    };
    # https://github.com/nixpak/nixpak/blob/master/modules/gui/fonts.nix
    # it works not well, bind system's /etc/fonts directly instead
    fonts.enable = false;
    # https://github.com/nixpak/nixpak/blob/master/modules/locale.nix
    locale.enable = true;
    bubblewrap = {
      network = lib.mkDefault false;
      bind.rw = [
        [
          (envSuffix "HOME" "/.var/app/${config.flatpak.appId}/cache")
          sloth.xdgCacheHome
        ]
        (sloth.concat' sloth.xdgCacheHome "/fontconfig")
        (sloth.concat' sloth.xdgCacheHome "/mesa_shader_cache")

        (sloth.concat [
          (sloth.env "XDG_RUNTIME_DIR")
          "/"
          (sloth.envOr "WAYLAND_DISPLAY" "no")
        ])

        (envSuffix "XDG_RUNTIME_DIR" "/at-spi/bus")
        (envSuffix "XDG_RUNTIME_DIR" "/gvfsd")
        (envSuffix "XDG_RUNTIME_DIR" "/pulse")

        "/run/dbus"
      ];
      bind.ro = [
        (envSuffix "XDG_RUNTIME_DIR" "/doc")
        (sloth.concat' sloth.xdgConfigHome "/dconf") # XCursor doesn't work without it in Firefox
        (sloth.concat' sloth.xdgConfigHome "/gtk-2.0")
        (sloth.concat' sloth.xdgConfigHome "/gtk-3.0")
        (sloth.concat' sloth.xdgConfigHome "/gtk-4.0")
        (sloth.concat' sloth.xdgConfigHome "/fontconfig")
        (sloth.concat' sloth.xdgConfigHome "/mimeapps.list")

        "/etc/fonts" # for fontconfig
        "/etc/machine-id"
        "/etc/localtime"

        # Fix: libEGL warning: egl: failed to create dri2 screen
        "/etc/egl"
        "/etc/static/egl"
      ];
      bind.dev = [
        # seems required when using nvidia as primary gpu
        "/dev/nvidia0"
        "/dev/nvidiactl"
        "/dev/nvidia-modeset"
        "/dev/nvidia-uvm"
      ];

      env = {
        XDG_DATA_DIRS = lib.mkForce (
          lib.makeSearchPath "share" (
            with pkgs;
            [
              cursor_theme
              papirus-icon-theme

              shared-mime-info
            ]
          )
        );
        XCURSOR_PATH = lib.mkForce (
          builtins.concatStringsSep ":" [
            "${cursor_theme}/share/icons"
            "${cursor_theme}/share/pixmaps"
          ]
        );
      };
    };
  };
}

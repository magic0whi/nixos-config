# Shared desktop runtime for nixpak wrapped GUI apps; portal and native
# services are opt-in. Compared with the old gui-base module it:
#   - drops the whole host environment (`clearEnv`) instead of inheriting it;
#   - exposes only the D-Bus proxy, never /run/dbus itself;
#   - gives each app private XDG dirs (see xdg-storage.nix) instead of a view
#     of the host home;
#   - gives each app a private /tmp and an app-scoped /etc/machine-id;
#   - reuses the host's fontconfig read-only instead of a sandbox font set.
# No host GVfs and no raw camera or PipeWire socket.
{
  config,
  lib,
  pkgs,
  sloth,
  ...
}:
{
  imports = [
    ./portal-groups.nix
    ./desktop-integration.nix
    ./xdg-storage.nix
  ];
  gpu = {
    enable = lib.mkDefault true;
    provider = "nixos";
    bundlePackage = pkgs.mesa.drivers; # for amd & intel
  };
  # https://github.com/nixpak/nixpak/blob/master/modules/locale.nix
  locale.enable = true;
  dbus = {
    policies = {
      "${config.flatpak.appId}" = "own";
      "${config.flatpak.appId}.*" = "own";
    };
    rules.call."org.freedesktop.portal.Desktop" = [
      "org.freedesktop.DBus.Properties.Get@/org/freedesktop/portal/desktop"
      "org.freedesktop.DBus.Properties.GetAll@/org/freedesktop/portal/desktop"
      "org.freedesktop.portal.Settings.Read@/org/freedesktop/portal/desktop"
      "org.freedesktop.portal.Settings.ReadAll@/org/freedesktop/portal/desktop"
      "org.freedesktop.portal.Request.Close@/org/freedesktop/portal/desktop/request/*"
      "org.freedesktop.portal.Session.Close@/org/freedesktop/portal/desktop/session/*"
    ];
    rules.broadcast."org.freedesktop.portal.Desktop" = [
      "org.freedesktop.portal.Settings.SettingChanged@/org/freedesktop/portal/desktop"
      "@/org/freedesktop/portal/desktop/*"
    ];
  };
  bubblewrap = {
    network = lib.mkDefault false;
    newSession = true;
    dieWithParent = true;
    clearEnv = true;
    sockets = {
      wayland = true;
      x11 = lib.mkDefault false;
      pulse = lib.mkDefault true;
      pipewire = lib.mkDefault false;
    };
    bind.rw =
      with sloth;
      [
        # Chrome/Firefox/Telegram/etc. use /tmp for single-instance IPC. Share
        # this directory across launches of the same app only; app IDs differ.
        [
          (mkdir (concat' runtimeDir "/nixpak-${config.flatpak.appId}-tmp"))
          "/tmp"
        ]
      ]
      # File chooser results arrive through the document portal; an app
      # without a chooser gets no view of the exported documents.
      ++ lib.optional config.portalGroups.fileChooser (concat' runtimeDir "/doc");
    bind.ro = [
      # libdbus aborts without /etc/machine-id. Every sandbox gets its own
      # stable, app-scoped value instead of the host's, so apps cannot use it
      # to correlate data across sandboxes.
      [
        (toString (
          pkgs.writeText "nixpak-machine-id-${config.flatpak.appId}" "${
            builtins.substring 0 32 (builtins.hashString "sha256" config.flatpak.appId)
          }\n"
        ))
        "/etc/machine-id"
      ]
      # Reuse the host's NixOS fontconfig. The font files and caches it
      # references live in /nix/store, which nixpak already mounts.
      [
        "/etc/static/fonts"
        "/etc/fonts"
      ]
      "/etc/localtime"
      "/etc/zoneinfo"
      "/sys/devices/platform"
    ]
    ++ lib.optionals config.gpu.enable [
      "/etc/egl"
      "/etc/static/egl"
    ];
    # nixpak's NixOS GPU provider maps DRM nodes, but NVIDIA also needs its
    # dedicated interfaces. Missing nodes are skipped by --dev-bind-try.
    bind.dev = lib.optionals config.gpu.enable [
      "/dev/nvidia0"
      "/dev/nvidiactl"
      "/dev/nvidia-modeset"
      "/dev/nvidia-uvm"
    ];
    # bwrap's `--dev` (apivfs.dev, on by default) already provides a private
    # /dev/shm sized at 50% of RAM, so it must not be bound from the host.
    env = {
      HOME = sloth.homeDir;
      USER = sloth.env "USER";
      XDG_RUNTIME_DIR = sloth.runtimeDir;
      XDG_CACHE_HOME = sloth.xdgCacheHome;
      XDG_CONFIG_HOME = sloth.xdgConfigHome;
      XDG_DATA_HOME = sloth.xdgDataHome;
      XDG_STATE_HOME = sloth.xdgStateHome;
      XDG_SESSION_TYPE = "wayland";
      # Selects the Wayland path for portal clients.
      XDG_CURRENT_DESKTOP = sloth.envOr "XDG_CURRENT_DESKTOP" "niri";
      WAYLAND_DISPLAY = sloth.envOr "WAYLAND_DISPLAY" "wayland-0";
      NIXOS_OZONE_WL = "1";
      GTK_USE_PORTAL = "1";
      GTK_A11Y = sloth.envOr "GTK_A11Y" "0";
      XDG_DATA_DIRS = lib.makeSearchPath "share" [
        pkgs.papirus-icon-theme
        pkgs.bibata-cursors
        pkgs.shared-mime-info
      ];
      XCURSOR_PATH = "${pkgs.bibata-cursors}/share/icons:${pkgs.bibata-cursors}/share/pixmaps";
      # Host NixOS fontconfig, bind-mounted above. A policy whose app builds
      # its own FHS layer overrides this (see modules/gaming-policy.nix).
      FONTCONFIG_FILE = lib.mkDefault "/etc/fonts/fonts.conf";
      NIXOS_XDG_OPEN_USE_PORTAL = "1";
    }
    // lib.genAttrs [
      "LANG"
      "LANGUAGE"
      "LC_ALL"
      "LC_ADDRESS"
      "LC_COLLATE"
      "LC_CTYPE"
      "LC_IDENTIFICATION"
      "LC_MEASUREMENT"
      "LC_MESSAGES"
      "LC_MONETARY"
      "LC_NAME"
      "LC_NUMERIC"
      "LC_PAPER"
      "LC_TELEPHONE"
      "LC_TIME"
      "XCURSOR_THEME"
      "XCURSOR_SIZE"
      "NO_AT_BRIDGE"
      "QT_QPA_PLATFORMTHEME"
      "QT_WAYLAND_DISABLE_WINDOWDECORATION"
      # ICU takes the zone name from the /etc/localtime symlink target path, but
      # the sandbox binds it as a plain file, leaving only the ambiguous "CST"
      # abbreviation; pass the name from the session.
      "TZ"
      "TZDIR"
    ] (name: sloth.envOr name "");
  };
}

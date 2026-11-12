# GUI Shell
{
  config,
  const,
  pkgs,
  ...
}:
{
  # Qt for noctalia-shell (replaces former systemd user service Environment=)
  home.sessionVariables = {
    # _JAVA_AWT_WM_NONREPARENTING = 1;
    # QT_WAYLAND_DISABLE_WINDOWDECORATION = 1; # Disables window decorations on Qt applications
    # SDL_VIDEODRIVER = "wayland";
    # GDK_BACKEND = "wayland";
    # Choose one
    QT_ENABLE_HIGHDPI_SCALING = 1;
    # QT_AUTO_SCREEN_SCALE_FACTOR = 1;
  };

  # Launcher usage, clipboard/notification history, community palettes and the
  # Settings UI overrides (settings.toml, loaded after config.toml and wins)
  home.persistence."/persistent".directories = [ ".local/state/noctalia" ];

  # https://docs.noctalia.dev/noctalia/configuration/
  # Defaults: https://github.com/noctalia-dev/noctalia/blob/v5.5.0/example.toml
  # TIP: to adjust `noctalia msg config-set widget.taskbar.icon_scale 0.9`
  # NOTE: Clean-up: rm ~/.local/state/noctalia/settings.toml
  programs.noctalia = {
    enable = true;
    settings = {
      shell = {
        # TODO: v5 takes a local path; v4 used
        # https://misc.s3-pub.proteus.eu.org/siameseemoji_agadmqeaaspumeu.png
        # avatar_path = "~/.face";
        # State is persisted, but keep the first-run wizard off on fresh installs
        setup_wizard_enabled = false;
        launch_apps_custom_command = "systemd-run --user --scope -- $CMD";
        panel.transparency_mode = "soft";
        screenshot.directory = "~/Pictures/Screenshots";
        # Session menu: an explicit list replaces the default five actions
        session = {
          grid = true;
          actions =
            let
              countdown_seconds = 10;
            in
            [
              {
                action = "lock";
                shortcut = "1";
              }
              {
                action = "suspend";
                shortcut = "2";
                inherit countdown_seconds;
              }
              {
                action = "command";
                label = "Hibernate";
                glyph = "zzz";
                command = "systemctl hibernate";
                shortcut = "3";
                inherit countdown_seconds;
              }
              {
                action = "reboot";
                shortcut = "4";
                inherit countdown_seconds;
              }
              {
                action = "logout";
                shortcut = "5";
                inherit countdown_seconds;
              }
              {
                action = "shutdown";
                shortcut = "6";
                variant = "destructive";
                inherit countdown_seconds;
              }
              {
                action = "reboot_uefi";
                shortcut = "7";
                inherit countdown_seconds;
              }
            ];
        };
      };

      wallpaper = {
        directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
        automation = {
          enabled = true;
          interval_seconds = 600;
          recursive = true;
        };
      };
      # Blurred wallpaper in niri's overview, see the `noctalia-backdrop` layer-rule in ./niri/noctalia.nix
      backdrop.enabled = true;

      theme.source = "wallpaper";

      location = {
        auto_locate = false;
        address = const.city;
      };
      weather.enabled = true;
      nightlight = {
        enabled = true;
        temperature_night = 2700;
      };

      brightness.enable_ddcutil = true;

      idle.behavior = {
        lock = {
          enabled = true;
          timeout = 600; # 10min
          action = "lock";
        };
        screen-off = {
          enabled = true;
          timeout = 630; # 10.5min
          action = "screen_off";
        };
      };

      system.monitor.cpu_usage_critical_threshold = 95; # Hot Intel

      dock.enabled = false;

      bar.main = {
        background_opacity = 0.8; # Shadow alpha is multiplied by this, too transparent leaves the bar shadowless
        margin_ends = 5;
        margin_edge = 2;
        padding = 3;
        capsule = true;
        scale = 1.1;
        start = [
          "launcher"
          "clock"
          "cpu"
          "ram"
          "disk"
          "net_rx"
          "net_tx"
          "media"
          "active_window"
        ];
        center = [ "taskbar" ];
        end = [
          "notifications"
          "battery"
          "volume"
          "brightness"
          "tray"
          "control-center"
        ];
      };

      widget = {
        cpu = {
          type = "sysmon";
          stat = "cpu_usage";
        };
        ram = {
          type = "sysmon";
          stat = "ram_pct";
        };
        disk = {
          type = "sysmon";
          stat = "disk_used_pct";
          path = "/persistent";
        };
        net_rx = {
          type = "sysmon";
          stat = "net_rx";
          network_speed_compact = true;
        };
        net_tx = {
          type = "sysmon";
          stat = "net_tx";
          network_speed_compact = true;
        };
        media = {
          hide_album_art = true;
          max_length = 500;
          hide_when_no_media = true;
        };
        taskbar = {
          group_by_workspace = true;
          workspace_group_content = "icons";
          group_single_icon_per_app = true;
          hide_empty_workspaces = true;
          label_source = "id";
          # Icons are clamped to the cross space left inside capsules, and `scale`
          # also grows the paddings (shrinking icons). Workspace groups draw their
          # own capsules, so drop the bar's outer one and size via icon_scale
          capsule = false;
        };
        tray = {
          colorize_icons = false; # Let applications use their builtin icon color
          drawer = true;
          pinned = [
            "Fcitx"
            "Feishin"
            "Syncthing Tray"
          ];
        };
        control-center.custom_image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      };
    };
  };

  home.packages = [ pkgs.gpu-screen-recorder ]; # recoding screen
}

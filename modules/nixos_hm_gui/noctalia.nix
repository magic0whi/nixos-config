{
  lib,
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

    # QT_QPA_PLATFORM = "wayland;xcb"; # Qt6: wayland primary, xcb fallback
    # QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  programs.noctalia-shell = {
    enable = true;
    settings = {
      appLauncher = {
        customLaunchPrefixEnabled = true;
        customLaunchPrefix = "systemd-run --user --scope -- ";
        enableClipboardHistory = true;
        iconMode = "native"; # Use system icon intead of default "tabler" icon
        showIconBackground = true;
        terminalCommand = "xdg-terminal-exec --";
      };
      audio = {
        volumeStep = 1;
      };
      bar = {
        backgroundOpacity = 0.2;
        density = "comfortable";
        hideOnOverview = true;
        marginHorizontal = 5;
        marginVertical = 5;
        useSeparateOpacity = true;
        widgets = {
          left = [
            {
              id = "Launcher";
            }
            {
              id = "Clock";
            }
            {
              id = "SystemMonitor";
              compactMode = false;
              showCpuUsage = true;
              showCpuTemp = false;
              showDiskUsage = true;
              diskPath = "/persistent";
              # showGpuTemp = false;
              showLoadAverage = true;
              showMemoryAsPercent = true;
              showNetworkStats = true;
            }
            { id = "ActiveWindow"; }
            {
              "id" = "MediaMini";
              showAlbumArt = false;
              maxWidth = 500;
            }
          ];
          center = [
            {
              id = "Workspace";
              showApplications = true;
              showApplicationsHover = true;
            }
          ];
          right = [
            { id = "NotificationHistory"; }
            {
              id = "Battery";
              displayMode = "icon-always";
              showNoctaliaPerformance = true;
              showPowerProfiles = true;
            }
            {
              id = "Volume";
              displayMode = "alwaysShow";
            }
            {
              id = "Brightness";
              displayMode = "alwaysShow";
            }
            {
              id = "Tray";
              colorizeIcons = false; # Default true. Disable to let applications use their builtin icon color
              pinned = [
                "tray-id" # Sunthine
                "udiskie"
                "virt-manager"
              ];
            }
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
          ];
        };
      };
      brightness = {
        brightnessStep = 3;
        enableDdcSupport = true;
      };
      colorSchemes.useWallpaperColors = true;
      controlCenter = {
        cards = [
          { id = "profile-card"; }
          { id = "shortcuts-card"; }
          { id = "audio-card"; }
          { id = "brightness-card"; } # enable, default false
          { id = "weather-card"; }
          { id = "media-sysmon-card"; }
        ];
        diskPath = "/persistent";
      };
      desktopWidgets = {
        enabled = true;
        gridSnap = true;
        monitorWidgets = [
          {
            name = "DP-3";
            widgets = [
              {
                id = "Clock";
                clockStyle = "digital";
                customFont = "";
                format = ''HH =mm\nd MMMM yyyy'';
                roundedCorners = true;
                scale = 0.7378548922663623;
                showBackground = true;
                useCustomFont = false;
                usePrimaryColor = false;
                x = 92;
                y = 161;
              }
              {
                id = "MediaPlayer";
                hideMode = "visible";
                roundedCorners = true;
                scale = 1.1501312913284876;
                showAlbumArt = true;
                showBackground = true;
                showButtons = true;
                showVisualizer = true;
                visualizerType = "linear";
                x = 92;
                y = 299;
              }
              {
                id = "Weather";
                scale = 1.339282355295889;
                showBackground = true;
                x = 230;
                y = 161;
              }
            ];
          }
        ];
      };
      dock.enabled = false;
      general.avatarImage = "https://misc.s3-pub.proteus.eu.org/siameseemoji_agadmqeaaspumeu.png";
      # TODO this would let user cannot unlock with loginctl unlock-session ID
      # hooks = {
      #   enabled = true;
      #   screenLock = "${pkgs.writeShellScript "lock-seat" ''
      #     SESSION_ID=$(loginctl -j list-sessions | jq -r --arg user "$USER" '.[] | select(.class == "user" and .seat != null and .user == $user) | .session')
      #     dbus-send --system --print-reply --dest=org.freedesktop.login1 \
      #       /org/freedesktop/login1/session/$SESSION_ID \
      #       org.freedesktop.login1.Session.SetLockedHint boolean:true
      #   ''}";
      # };
      location = {
        autoLocate = false;
        name = const.city;
      };
      nightLight = {
        enabled = true;
        # manualSunrise = "06:30";
        # manualSunset = "18:30";
      };
      osd.enabledTypes = [
        0
        1
        2
        3
      ];
      sessionMenu = {
        largeButtonsLayout = "grid";
        powerOptions = [
          {
            action = "lock";
            enabled = true;
            keybind = "1";
          }
          {
            action = "suspend";
            countdownEnabled = true;
            enabled = true;
            keybind = "2";
          }
          {
            action = "hibernate";
            countdownEnabled = true;
            enabled = true;
            keybind = "3";
          }
          {
            action = "reboot";
            countdownEnabled = true;
            enabled = true;
            keybind = "4";
          }
          {
            action = "logout";
            countdownEnabled = true;
            enabled = true;
            keybind = "5";
          }
          {
            action = "shutdown";
            countdownEnabled = true;
            enabled = true;
            keybind = "6";
          }
          {
            action = "rebootToUefi";
            countdownEnabled = true;
            enabled = true;
            keybind = "7";
          }
        ];
      };
      systemMonitor.cpuCriticalThreshold = 95; # Hot Intel
      ui.panelBackgroundOpacity = 0.85;
      wallpaper = {
        automationEnabled = true;
        # directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
        overviewEnabled = true;
        randomIntervalSec = 600;
        viewMode = "recursive";
      };
    };
    plugins.sources = lib.singleton {
      enabled = true;
      name = "Official Noctalia Plugins";
      url = "https://github.com/noctalia-dev/noctalia-plugins";
    };
  };

  # recoding screen
  home.packages = [ pkgs.gpu-screen-recorder ];
}

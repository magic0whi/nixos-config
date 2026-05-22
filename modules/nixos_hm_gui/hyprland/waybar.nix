{
  config,
  lib,
  ...
}: {
  programs.ashell = {
    enable = true;
    systemd.enable = true;
    settings = {
      CustomModule = [
        {
          name = "appLauncher";
          icon = ""; # nf-linux-nixos
          command = "walker";
        }
      ];
      modules = {
        left = [["appLauncher" "Workspaces"]];
        center = ["WindowTitle"];
        right = ["SystemInfo" "MediaPlayer" ["Tray" "Tempo" "Privacy" "Settings"]];
      };
    };
  };
  # Waybar sometimes starts too fast before hyprland is ready
  systemd.user.services = lib.mkIf config.programs.waybar.enable {waybar.Service.RestartSec = "3.02s";};
  programs.waybar = {
    enable = false;
    systemd.enable = true;
    # systemd.enableInspect = true; # DEBUG: GTK Inspector
    settings = let
      launch_prefix = "systemd-run --user --scope --";
    in [
      {
        modules-left = ["custom/launcher" "custom/powermenu" "hyprland/workspaces" "hyprland/submap"];
        modules-center = ["hyprland/window"];
        modules-right = [
          "mpd"
          "idle_inhibitor"
          "pulseaudio"
          "network"
          "power-profiles-daemon"
          "group/hw_info"
          "backlight"
          "keyboard-state"
          "clock"
          "tray"
          "privacy"
        ];
        "group/hw_info" = {
          orientation = "horizontal";
          modules = ["cpu" "memory" "temperature" "battery"];
        };
        "custom/launcher" = {
          format = "&#xf313;"; # nf-linux-nixos
          tooltip = false;
          on-click = "${launch_prefix} ${config.programs.anyrun.menu_script}";
          # on-click-middle = ""; # TODO: Impl random wallpaper
          # on-click-right = ""; # TODO: Impl next wallpaper
        };
        "custom/powermenu" = {
          format = "&#xf011;"; # nf-fa-power_off
          tooltip = false;
          on-click = "${launch_prefix} ${config.programs.wlogout.wrapper_script}";
        };
        "hyprland/workspaces" = {
          format = "{name}{windows}";
          show-special = true;
          special-visible-only = true; # special workspaces will be shown only if visible.
          window-rewrite-default = "&#xf059;"; # nf-fa-question_circle
          window-rewrite = {
            "class<.virt-manager-wrapped|Qemu-system-x86_64>" = "&#xeb7b;"; # nf-cod-vm_running
            "class<ario>" = "&#xf0386;"; # music_circle
            "class<blender>" = "&#xf00ab;"; # blender_software
            "class<blueman-manager|.blueman-manager-wrapped>" = "&#xf293;"; # nf-fa-bluetooth
            "class<com.obsproject.Studio>" = "&#xf0210;"; # fan
            "class<firefox>" = "&#xf0239;"; # firefox
            "class<gamescope>" = "&#xf0297;"; # gamepad_variant
            "class<google-chrome>" = "&#xf268;"; # nf-fa-chrome
            "class<hyprland-share-picker>" = "&#xf0496;"; # share
            "class<imv>" = "&#xf02e9;"; # image
            "class<localsend|localsend_app>" = "&#xf04b8;"; # soccer
            "class<mpv>" = "&#xf36e;"; # linux-mpv
            "class<org.fcitx.fcitx5-config-qt>" = "&#xf09f9;"; # keyboard_settings
            "class<org.gnome.Nautilus|Thunar>" = "&#xf024b;"; # folder
            "class<org.inkscape.Inkscape>" = "&#xf33b;"; # linux-inkscape
            "class<org.pwmt.zathura>" = "&#xf292;"; # hashtag
            "class<org.remmina.Remmina>" = "&#xeb39;"; # nf-md-remote
            "class<org.telegram.desktop>" = "&#xf2c6;"; # telegram
            "class<python3>" = "&#xf0320;"; # nf-md-language_python
            "class<steam|SDL Application>" = "&#xf04d3;"; # steam
            "class<waybar>" = "&#xebdc;"; # debug_all
            "class<Alacritty>" = "&#xf018d;"; # console
            "class<Anki>" = "&#xf0638;"; # cards
            "class<org.keepassxc.KeePassXC>" = "&#xf0bc4;"; # shield_key
            "class<Minecraft|modrinth-app>" = "&#xf0373;"; # minecraft
            "class<GeoGebra>" = "&#xf1ec;"; # nf-fa-calculator
            "class<libreoffice-calc>" = "&#xf378;"; # nf-linux-libreofficecalc
            "class<libreoffice-startcenter>" = "&#xf376;"; # nf-linux-libreoffice
            "class<qemu>" = "&#xeb7b;"; # nf-cod-vm_running
            "class<superProductivity>" = "&#xf1ad0;"; # nf-md-timer_check
            "class<electron>" = "&#xe62e;"; # nf-custom-electron
          };
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "&#xf1802;"; # nf-md-lightbulb_variant
            deactivated = "&#xf0336;"; # nf-md-lightbulb_outline
          };
        };
        tray = {
          icon-size = 20;
          spacing = 6;
        };
        clock = {
          actions = {
            on-click-right = "tz_down";
            on-scroll-up = "tz_up";
            on-scroll-down = "tz_down";
          };
          format = "{:%H:%M:%S (%Z)}";
          format-alt = "{:%m-%d-%y}";
          interval = 1;
          timezones = ["Asia/Hong_Kong" "Europe/London" "US/Eastern"];
          tooltip-format = "<big>{:%y %b}</big>\n<tt><small>{calendar}</small></tt>";
        };
        cpu = {
          format = "{usage}% &#xf0ee0;"; # cpu_64_bit
          tooltip = false;
        };
        memory = {
          format = "{percentage}% &#xf035b;"; # memory
          states = {warning = 85;};
        };
        temperature = {
          # hwmon-path = "/sys/class/hwmon/hwmon5/temp1_input"; # Vary on different devices
          critical-threshold = 85;
          format-critical = "{temperatureC}&#xb0;C &#xf0e01;"; # thermometer_alert
          format = "{temperatureC}&#xb0;C {icon}";
          format-icons = [
            "&#xf10c3;" # thermometer_low
            "&#xf050f;" # thermometer
            "&#xf10c2;" # thermometer_high
          ];
          tooltip = false;
        };
        backlight = {
          # on-scroll-up = "brightnessctl set +4%"; # Some devices may need set manually
          # on-scroll-down = "brightnessctl set 4%-";
          format = "{percent}% {icon}";
          format-icons = [
            "&#xf00da;" # brightness_1
            "&#xf00db;" # brightness_2
            "&#xf00dc;" # brightness_3
            "&#xf00de;" # brightness_5
            "&#xf00dd;" # brightness_4
            "&#xf00df;" # brightness_6
            "&#xf00e0;" # brightness_5
          ];
          tooltip = false;
        };
        keyboard-state = {
          numlock = false;
          capslock = true;
          format = "{name} {icon}";
          format-icons = {
            locked = "&#xf0a9b;"; # caps_lock
            unlocked = "&#xf030e;"; # keyboard_caps
          };
        };
        battery = {
          states = {
            # good = 95;
            warning = 20;
            critical = 10;
          };
          format = "{capacity}% {icon}";
          format-full = "{capacity}% {icon}";
          format-charging = "{capacity}% &#xf0084;"; # battery_charging
          format-plugged = "{capacity}% &#xf1834;"; # battery_sync
          format-alt = "{time} {power}W {icon}";
          # format-good = ""; # an empty format will hide the module
          # format-full = "";
          format-icons = [
            "&#xf10cd;" # battery_alert_variant_outline
            "&#xf007a;" # battery_10
            "&#xf007b;" # battery_20
            "&#xf007c;" # battery_30
            "&#xf007d;" # battery_40
            "&#xf007e;" # battery_50
            "&#xf007f;" # battery_60
            "&#xf0080;" # battery_70
            "&#xf0081;" # battery_80
            "&#xf0082;" # battery_90
            "&#xf0079;" # battery
          ];
        };
        power-profiles-daemon = {
          format = "{icon}";
          tooltip-format = "power profile: {profile}\ndriver: {driver}";
          tooltip = true;
          format-icons = {
            default = "&#xf0210;"; # fan
            performance = "&#xf1807;"; # fire_circle
            balanced = "&#xf1a04;"; # percent_circle
            power-saver = "&#xf1905;"; # leaf_circle
          };
        };
        network = {
          # interface = "wlan0"; # NOTE: Vary on different devices
          format-wifi = "{icon}";
          format-ethernet = "{ipaddr}/{cidr} &#xf0200;"; # ethernet
          format-linked = "{ifname} (no ip) &#xf0318;"; # lan_connect
          format-disconnected = "disconnected &#xf0319;"; # lan_disconnect
          format-alt = "&#xf106; {bandwidthUpBytes} | &#xf107; {bandwidthDownBytes}"; # nf-fa-angle_up, nf-fa-angle_down
          tooltip-format = "{ifname} via {gwaddr} &#xf11e2;\n{ipaddr}/{cidr}"; # router
          tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ifname} via {gwaddr} &#xf11e2;"; # router
          format-icons = [
            "&#xf092f;" # wifi_strength_outline
            "&#xf091f;" # wifi_strength_1
            "&#xf0922;" # wifi_strength_2
            "&#xf0925;" # wifi_strength_3
            "&#xf0928;" # wifi_strength_4
          ];
          on-click-right = "${lib.getExe config.xdg.terminal-exec.package} sudo iwctl";
        };
        pulseaudio = {
          # scroll-step = 1, # %, can be a float
          format = "{volume}% {icon} {format_source}";
          format-muted = "&#xf0581; {format_source}"; # volume_off
          format-bluetooth = "{volume}% {icon}&#xf00af; {format_source}"; # bluetooth
          format-bluetooth-muted = "&#xf0581;{icon}&#xf00af; {format_source}"; # volume_off, bluetooth
          format-source = "{volume}% &#xf036c;"; # microphone
          format-source-muted = "&#xf036d;"; # microphone_off
          format-icons = {
            headphone = "&#xf02cb;"; # headphones
            hands-free = "&#xf184f;"; # earbuds
            headset = "&#xf02ce;"; # headset
            phone = "&#xf03f2;"; # phone
            portable = "&#xf011c;"; # cellphone
            car = "&#xf010b;"; # car
            default = [
              "&#xf057f;" # volume_low
              "&#xf0580;" # volume_medium
              "&#xf057e;" # volume_high
            ];
          };
          on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
          on-click-middle = "pavucontrol";
          on-click-right = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
        };
        privacy = {
          icon-spacing = 4;
          icon-size = 18;
          transition-duration = 250;
          modules = [
            {
              type = "screenshare";
              tooltip = true;
              tooltip-icon-size = 22;
            }
            {
              type = "audio-out";
              tooltip = true;
              tooltip-icon-size = 22;
            }
            {
              type = "audio-in";
              tooltip = true;
              tooltip-icon-size = 22;
            }
          ];
        };
        mpd = {
          title-len = 10;
          on-click = "mpc toggle";
          on-click-middle = "mpc prev";
          on-click-right = "mpc next";
          on-scroll-down = "mpc seek -00:00:01";
          on-scroll-up = "mpc seek +00:00:01";
          format = "{stateIcon}{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) &#xf075a;"; # music
          format-disconnected = "Disconnected &#xf0319;"; # lan_disconnect
          format-stopped = "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped &#xf075b;"; # music_off
          consume-icons = {
            on = "&#xf0190;"; # content_cut
          };
          random-icons = {
            off = "&#xf049e;"; # shuffle_disabled
            on = "&#xf049d;"; # shuffle
          };
          repeat-icons.on = "&#xf0456;"; # repeat
          single-icons.on = "&#xf0458;"; # repeat_once
          state-icons = {
            paused = "&#xf03e4;"; # pause
            playing = "&#xf040a;"; # play
          };
          tooltip-format = "MPD (connected)";
          tooltip-format-disconnected = "MPD (disconnected)";
        };
      }
    ];
    style = ''
      /* Run 'waybar -l debug' to viewing the widget tree */
      /* https://www.w3.org/TR/selectors-3 */
      /* https://docs.gtk.org/gtk3/css-properties.html */
      /* https://docs.gtk.org/gtk3/css-overview.html#colors */
      /* Specificity
      a = Number of ID selectors
      b = number of class selectors
      c = number of type selectors
      */

      window#waybar {
        background-color: transparent;
        color: @teal;
        font-family: Symbols Nerd Font, monospace;
        /* font-size: 16px; */
      }
      window#waybar>box {margin: 6px 6px 0;} /* top | left & right | bottom */

      tooltip {
        background-color: @base;
        border: 2px solid @overlay2;
        color: @teal;
        /* font-size: 16px; */
      }

      .module, #privacy { margin: 0 2px; } /* Privacy lacks class .module */

      /* Omit left margin for the leftmost module */
      .modules-left>widget:first-child>.module {margin-left: 0;}

      /* Omit right margin for the rightmost module */
      .modules-right>widget:last-child>.module,
      .modules-right>widget:last-child>#privacy {margin-right: 0;} /* Privacy lacks class .module */

      #backlight,
      #battery,
      #clock,
      #cpu,
      #custom-launcher,
      #custom-powermenu,
      #idle_inhibitor,
      #keyboard-state,
      #memory,
      #mpd,
      #network,
      #power-profiles-daemon,
      #privacy,
      #pulseaudio,
      #submap,
      #temperature,
      #tray,
      #window,
      #workspaces {
        background-color: @base;
        border-radius: 8px;
        padding: 0 5px;
        transition-property: background-color;
        transition-duration: .5s;
      }

      #battery.charging, #battery.plugged {background-color: @green; color: @base;}

      #battery:hover,
      #clock:hover,
      #custom-launcher:hover, #custom-powermenu:hover,
      #idle_inhibitor:hover,
      #network:hover,
      #pulseaudio:hover,
      #workspaces button:hover,
      #workspaces button.active,
      #idle_inhibitor.activated,
      #keyboard-state>label.locked,
      #privacy {background-color: @pink; color: @base;}

      @keyframes blink {
        to {
          background-color: @base;
          color: @teal;
        }
      }

      /* Using steps() instead of linear as a timing function to limit cpu usage */
      #battery.critical:not(.charging),
      #temperature.critical {
        background-color: @red;
        color: @base;
        animation-name: blink;
        animation-duration: .5s;
        animation-timing-function: steps(12);
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      #battery.warning:not(.charging),
      #memory.warning {background-color: @peach; color: @base;}

      #keyboard-state, #privacy, #window, #workspaces {padding: 0;} /* Remove parent box's padding */
      #keyboard-state>label, #privacy-item, #workspaces button {padding: 0 5px;}

      #keyboard-state>label.locked {border-radius: inherit;} /* It didn't inherit radius */

      #mpd.disconnected {background-color: @red; color: @base;}
      #mpd.paused {background-color: @yellow; color: @base;}
      #mpd.stopped {background-color: @blue; color: @base;}

      #network.disconnected {background-color: @red;}

      #power-profiles-daemon.performance {background-color: @red; color: @base;}
      #power-profiles-daemon.balanced {background-color: @blue; color: @base;}
      #power-profiles-daemon.power-saver {background-color: @green; color: @base;}

      #pulseaudio.muted {color: @overlay2;}

      #tray>.passive {-gtk-icon-effect: dim;}
      #tray>.needs-attention {-gtk-icon-effect: highlight; background-color: @red;}

      #window, #workspaces {background-color: transparent;}
      #workspaces button {
        background-color: @base;
        color: inherit;
        transition-duration: inherit;
      }
      #workspaces button.urgent {background-color: @red; color: @base;}

      /* Concatnate modules in a module group */
      #hw_info widget:not(:first-child):not(:last-child) .module,
      #workspaces button:not(:first-child):not(:last-child) {
        border-radius: 0; margin: 0;
      }
      #hw_info widget:first-child .module,
      #workspaces button:first-child {
        border-top-right-radius: 0; border-bottom-right-radius: 0; margin-right: 0;
      }
      #hw_info widget:last-child .module,
      #workspaces button:last-child {
        border-top-left-radius: 0; border-bottom-left-radius: 0; margin-left: 0;
      }
      #hw_info widget:only-child .module,
      #workspaces button:only-child {border-radius: inherit;}
    '';
  };
}

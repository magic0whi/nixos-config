{
  config,
  lib,
  pkgs,
  ...
}: let
  hypr_pkg = pkgs.hyprland;
in {
  # NOTE: this executable is used by Greetd to start a wayland session when system boot up. With such a
  # vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config in NixOS
  # module
  home.file.".wayland-session".source = "${hypr_pkg}/bin/start-hyprland";
  catppuccin.hyprland.enable = false;
  wayland.windowManager.hyprland = {
    enable = true;
    package = hypr_pkg;
    # configType = "hyprlang";
    systemd.variables = ["--all"];
    settings = {
      env = [
        # "_JAVA_AWT_WM_NONREPARENTING,1"
        # "QT_WAYLAND_DISABLE_WINDOWDECORATION,1" # Disables window decorations on Qt applications
        # "QT_QPA_PLATFORM,wayland"
        # "SDL_VIDEODRIVER,wayland"
        # "GDK_BACKEND,wayland"
        {_args = ["QT_ENABLE_HIGHDPI_SCALING" "1"];}
      ];

      # Variables
      a_launch_prefix._var = "systemd-run --user --scope -- ";
      a_terminal._var = lib.getExe config.xdg.terminal-exec.package;
      # clip_manager = "sh -c 'cliphist list | rofi -dmenu | cliphist decode | wl-copy'";
      clip_manager._var = config.programs.anyrun.clip_script;
      color_picker._var = pkgs.writeShellScript "menu" ''
        ## Simple Script To Pick Color Quickly.
        color=$(hyprpicker)
        image=/tmp/$color.png

        if [ -n "$color" ]; then
          # Copy color code to clipboard
          echo $color | tr -d "\n" | wl-copy
          # Generate preview
          convert -size 48x48 xc:"$color" $image
          # Notify about it
          notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i $image "$color, copied to clipboard."
        fi
      '';
      file_manager._var = lib.generators.mkLuaInline ''a_terminal .. " yazi"'';
      main_mod._var = "SUPER";
      # menu._var = "rofi -show combi";
      menu._var = config.programs.anyrun.menu_script;
      wlogout._var = config.programs.wlogout.wrapper_script;

      # This will get rid of the pixelated look, but will not scale applications properly. To do this, each toolkit has
      # its own mechanism.
      config = {
        general = {
          border_size = 2;
          gaps_in = 2; # gaps between windows
          gaps_out = 5; # gaps between windows and monitor edges
          col = {
            active_border = {
              colors = ["rgba(33ccffee)" "rgba(00ff99ee)"];
              angle = 45;
            };
            inactive_border = "rgba(595959aa)";
          };
        };
        gesture = ["3,horizontal,workspace"];
        decoration = {
          rounding = 10;
          inactive_opacity = 0.9;
          # Your blur "amount" is blur:size * blur:passes, but high blur_size (over around 5-ish) will produce
          # artifacts. If you want heavy blur, you need to up the blur_passes. The more passes, the more you can up the
          # blur:size without noticeable artifacts.
          blur = {
            enabled = false;
            size = 3;
            ignore_opacity = false;
          };
          shadow.enabled = false;
        };
        # The split (side/top) will not change regardless of what happens to the container
        dwindle.preserve_split = true;
        misc = {
          key_press_enables_dpms = true;
          vrr = 1;
          # https://github.com/hyprwm/hyprlock/issues/779
          allow_session_lock_restore =
            if config.programs.hyprlock.enable
            then true
            else false;
        };
        xwayland.force_zero_scaling = true;
      };
      curve = [
        {
          # https://easings.net/#easeOutQuint
          _args = [
            "easeOutQuint"
            {
              type = "bezier";
              points = [[0.23 1] [0.32 1]];
            }
          ];
        }
        {
          # https://cubic-bezier.com/#0,0,1,1
          _args = [
            "linear"
            {
              type = "bezier";
              points = [[0 0] [1 1]];
            }
          ];
        }
        {
          # https://cubic-bezier.com/#.5,.5,.75,1
          _args = [
            "almostLinear"
            {
              type = "bezier";
              points = [[0.5 0.5] [0.75 1.0]];
            }
          ];
        }
        {
          # https://cubic-bezier.com/#.15,0,.1,1
          _args = [
            "quick"
            {
              type = "bezier";
              points = [[0.15 0] [0.1 1]];
            }
          ];
        }
        {
          _args = [
            "easy"
            {
              type = "spring";
              mass = 1;
              stiffness = 71.2633;
              dampening = 15.8273644;
            }
          ];
        }
      ];

      animation = [
        {
          leaf = "global";
          enabled = true;
          speed = 10;
          bezier = "default";
        }
        {
          leaf = "border";
          enabled = true;
          speed = 5.39;
          bezier = "easeOutQuint";
        }
        {
          leaf = "windows";
          enabled = true;
          speed = 4.79;
          spring = "easy";
        }
        {
          leaf = "border";
          enabled = true;
          speed = 5.39;
          bezier = "easeOutQuint";
        }
        {
          leaf = "windowsIn";
          enabled = true;
          speed = 4.1;
          spring = "easy";
          style = "popin 87%";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = 1.49;
          bezier = "linear";
          style = "popin 87%";
        }
        {
          leaf = "fadeIn";
          enabled = true;
          speed = 1.73;
          bezier = "almostLinear";
        }
        {
          leaf = "fadeOut";
          enabled = true;
          speed = 1.46;
          bezier = "almostLinear";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 3.03;
          bezier = "quick";
        }
        {
          leaf = "layers";
          enabled = true;
          speed = 3.81;
          bezier = "easeOutQuint";
        }
        {
          leaf = "layersIn";
          enabled = true;
          speed = 4;
          bezier = "easeOutQuint";
          style = "fade";
        }
        {
          leaf = "layersOut";
          enabled = true;
          speed = 1.5;
          bezier = "linear";
          style = "fade";
        }
        {
          leaf = "fadeLayersIn";
          enabled = true;
          speed = 1.79;
          bezier = "almostLinear";
        }
        {
          leaf = "fadeLayersOut";
          enabled = true;
          speed = 1.39;
          bezier = "almostLinear";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 1.94;
          bezier = "almostLinear";
          style = "fade";
        }
        {
          leaf = "workspacesIn";
          enabled = true;
          speed = 1.21;
          bezier = "almostLinear";
          style = "fade";
        }
        {
          leaf = "workspacesOut";
          enabled = true;
          speed = 1.94;
          bezier = "almostLinear";
          style = "fade";
        }
        {
          leaf = "zoomFactor";
          enabled = true;
          speed = 7;
          bezier = "quick";
        }
      ];
      bind = with lib.generators;
        [
          # Applications
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + Q"'')
              (mkLuaInline "hl.dsp.exec_cmd(a_launch_prefix .. a_terminal)")
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + E"'')
              (mkLuaInline ''hl.dsp.exec_cmd(a_launch_prefix .. file_manager)'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + SPACE"'')
              (mkLuaInline "hl.dsp.exec_cmd(a_launch_prefix .. menu)")
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + V"'')
              (mkLuaInline "hl.dsp.exec_cmd(a_launch_prefix .. clip_manager)")
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + CTRL + "'')
              (mkLuaInline "hl.dsp.exec_cmd(a_launch_prefix .. color_picker)")
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + X"'')
              (mkLuaInline "hl.dsp.exec_cmd(a_launch_prefix .. wlogout)")
            ];
          }

          # Window management
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + W"'')
              (mkLuaInline "hl.dsp.window.close()")
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + F"'')
              (mkLuaInline "hl.dsp.window.fullscreen()")
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + SHIFT + F"'')
              (mkLuaInline ''hl.dsp.window.float({ action = "toggle" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + G"'')
              (mkLuaInline ''
                function()
                  hl.dispatch(hl.dsp.window.float({ action = "enable" }))
                  hl.dispatch(hl.dsp.window.pin())
                end
              '')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + T"'')
              (mkLuaInline ''hl.dsp.layout("togglesplit")'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + SHIFT + P"'')
              (mkLuaInline "hl.dsp.window.pseudo()")
            ];
          }

          # Special Workspace (Scratchpad)
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + S"'')
              (mkLuaInline ''hl.dsp.workspace.toggle_special("magic")'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + SHIFT + S"'')
              (mkLuaInline ''hl.dsp.window.move({ workspace = "special:magic" })'')
            ];
          }

          # Focus Movement
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + H"'')
              (mkLuaInline ''hl.dsp.focus({ direction = "l" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + J"'')
              (mkLuaInline ''hl.dsp.focus({ direction = "d" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + K"'')
              (mkLuaInline ''hl.dsp.focus({ direction = "u" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + L"'')
              (mkLuaInline ''hl.dsp.focus({ direction = "r" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + N"'')
              (mkLuaInline ''hl.dsp.window.cycle_next()'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + P"'')
              (mkLuaInline ''hl.dsp.window.cycle_next({ next = false })'')
            ];
          }

          # Move Windows
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + SHIFT + H"'')
              (mkLuaInline ''hl.dsp.window.move({ direction = "l" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + SHIFT + J"'')
              (mkLuaInline ''hl.dsp.window.move({ direction = "d" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + SHIFT + K"'')
              (mkLuaInline ''hl.dsp.window.move({ direction = "u" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + SHIFT + L"'')
              (mkLuaInline ''hl.dsp.window.move({ direction = "r" })'')
            ];
          }

          # Workspace Scrolling
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + mouse_down"'')
              (mkLuaInline ''hl.dsp.focus({ workspace = "e+1" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + mouse_up"'')
              (mkLuaInline ''hl.dsp.focus({ workspace = "e-1" })'')
            ];
          }

          # Screenshots
          {
            _args = [
              (mkLuaInline ''"Print"'')
              (mkLuaInline
                ''hl.dsp.exec_cmd(a_launch_prefix .. "hyprshot -m output -o ~/Pictures/Screenshots -- imv")'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''"ALT + Print"'')
              (mkLuaInline
                ''hl.dsp.exec_cmd(a_launch_prefix .. "hyprshot -m window -o ~/Pictures/Screenshots -- imv")'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''"CTRL + Print"'')
              (mkLuaInline
                ''hl.dsp.exec_cmd(a_launch_prefix .. "hyprshot -m region -o ~/Pictures/Screenshots -- imv")'')
            ];
          }

          # Window Resizing (Repeating)
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + ALT + H"'')
              (mkLuaInline ''hl.dsp.window.resize({ x = -38.4, y = 0, relative = true })'')
              {repeating = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + ALT + L"'')
              (mkLuaInline ''hl.dsp.window.resize({ x = 38.4, y = 0, relative = true })'')
              {repeating = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + ALT + J"'')
              (mkLuaInline ''hl.dsp.window.resize({ x = 0, y = 21.6, relative = true })'')
              {repeating = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + ALT + K"'')
              (mkLuaInline ''hl.dsp.window.resize({ x = 0, y = -21.6, relative = true })'')
              {repeating = true;}
            ];
          }

          # Media Keys (Locked & Repeating)
          {
            _args = [
              (mkLuaInline ''"XF86AudioRaiseVolume"'')
              (mkLuaInline ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")'')
              {
                repeating = true;
                locked = true;
              }
            ];
          }
          {
            _args = [
              (mkLuaInline ''"XF86AudioLowerVolume"'')
              (mkLuaInline ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")'')
              {
                repeating = true;
                locked = true;
              }
            ];
          }
          {
            _args = [
              (mkLuaInline ''"XF86AudioMute"'')
              (mkLuaInline ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'')
              {
                repeating = true;
                locked = true;
              }
            ];
          }
          {
            _args = [
              (mkLuaInline ''"XF86AudioMicMute"'')
              (mkLuaInline ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")'')
              {
                repeating = true;
                locked = true;
              }
            ];
          }
          {
            _args = [
              (mkLuaInline ''"XF86MonBrightnessUp"'')
              (mkLuaInline ''hl.dsp.exec_cmd("brightnessctl set +4%")'')
              {
                repeating = true;
                locked = true;
              }
            ];
          }
          {
            _args = [
              (mkLuaInline ''"XF86MonBrightnessDown"'')
              (mkLuaInline ''hl.dsp.exec_cmd("brightnessctl set 4%-")'')
              {
                repeating = true;
                locked = true;
              }
            ];
          }
          {
            _args = [
              (mkLuaInline ''"XF86AudioNext"'')
              (mkLuaInline ''hl.dsp.exec_cmd("mpc next")'')
              # Or
              # (mkLuaInline ''hl.dsp.exec_cmd("playerctl --all-players next")'')
              {
                repeating = true;
                locked = true;
              }
            ];
          }
          {
            _args = [
              (mkLuaInline ''"XF86AudioPrev"'')
              (mkLuaInline ''hl.dsp.exec_cmd("mpc prev")'')
              # Or
              # (mkLuaInline ''hl.dsp.exec_cmd("playerctl --all-players previous")'')
              {
                repeating = true;
                locked = true;
              }
            ];
          }
          {
            _args = [
              (mkLuaInline ''"XF86AudioPlay"'')
              (mkLuaInline ''hl.dsp.exec_cmd("mpc toggle")'')
              # Or
              # (mkLuaInline ''hl.dsp.exec_cmd("playerctl --all-players play-pause")'')
              {
                repeating = true;
                locked = true;
              }
            ];
          }
          {
            _args = [
              (mkLuaInline ''"XF86AudioStop"'')
              (mkLuaInline ''hl.dsp.exec_cmd("mpc stop")'')
              # Or
              # (mkLuaInline ''hl.dsp.exec_cmd("playerctl --all-players stop")'')
              {
                repeating = true;
                locked = true;
              }
            ];
          }

          # System controls (Locked)
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + Z"'')
              (mkLuaInline ''hl.dsp.exec_cmd("loginctl lock-session")'')
              {locked = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + CTRL + SHIFT + Q"'')
              (mkLuaInline ''hl.dsp.exec_cmd("loginctl terminate-user $USER")'')
              {locked = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + CTRL + SHIFT + W"'')
              (mkLuaInline ''hl.dsp.exec_cmd("systemctl suspend")'')
              {locked = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + CTRL + SHIFT + E"'')
              (mkLuaInline ''hl.dsp.exec_cmd("systemctl hibernate")'')
              {locked = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + CTRL + SHIFT + R"'')
              (mkLuaInline ''hl.dsp.exec_cmd("systemctl reboot")'')
              {locked = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + CTRL + SHIFT + T"'')
              (mkLuaInline ''hl.dsp.exec_cmd("systemctl poweroff")'')
              {locked = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''"switch:Lid Switch"'')
              (mkLuaInline ''hl.dsp.exec_cmd("loginctl lock-session")'')
              {locked = true;}
            ];
          }

          # Mouse actions
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + mouse:272"'')
              (mkLuaInline "hl.dsp.window.drag()")
              {mouse = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + mouse:273"'')
              (mkLuaInline "hl.dsp.window.resize()")
              {mouse = true;}
            ];
          }
        ]
        ++ (builtins.concatLists (builtins.genList (
            i: let
              ws_num =
                if i == 0
                then 10
                else i;
            in [
              {
                _args = [
                  (lib.generators.mkLuaInline ''main_mod  .. " + ${toString i}"'')
                  (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = ${toString ws_num} })")
                ];
              }
              {
                _args = [
                  (lib.generators.mkLuaInline ''main_mod  .. " + SHIFT + ${toString i}"'')
                  (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = ${toString ws_num} })")
                ];
              }
            ]
          )
          10));

      # bind = [
      #   "$main_mod ,E,exec,${a_launch_prefix} $file_manager"
      #   "$main_mod ,Q,exec,${a_launch_prefix} $a_terminal"
      #   "$main_mod ,SPACE,exec,${a_launch_prefix} $menu"
      #   "$main_mod ,V,exec,${a_launch_prefix} $clip_manager"
      #   "$main_mod  CTRL,P,exec,${a_launch_prefix} $colorpicker"
      #   "$main_mod ,X,exec,${a_launch_prefix} $wlogout"
      #   "$main_mod ,W,killactive,"
      #   "$main_mod ,F,fullscreen,"
      #   "$main_mod  SHIFT,F,togglefloating"
      #   "$main_mod ,G,exec,hyprctl dispatch setfloating && hyprctl dispatch pin"
      #   "$main_mod ,T,layoutmsg,togglesplit" # dwindle
      #   "$main_mod  SHIFT,P,pseudo" # dwindle"

      #   # Special workspace (scratchpad)
      #   "$main_mod ,S,togglespecialworkspace,magic"
      #   "$main_mod  SHIFT,S,movetoworkspace,special:magic"

      #   # Move focus
      #   "$main_mod ,H,movefocus,l"
      #   "$main_mod ,J,movefocus,d"
      #   "$main_mod ,K,movefocus,u"
      #   "$main_mod ,L,movefocus,r"
      #   "$main_mod ,N,cyclenext,"
      #   "$main_mod ,P,cyclenext,prev"

      #   # Move windows
      #   "$main_mod  SHIFT,H,movewindow,l"
      #   "$main_mod  SHIFT,J,movewindow,d"
      #   "$main_mod  SHIFT,K,movewindow,u"
      #   "$main_mod  SHIFT,L,movewindow,r"

      #   # Scroll through existing workspaces with main_mod  + scroll
      #   "$main_mod ,mouse_down,workspace,e+1"
      #   "$main_mod ,mouse_up,workspace,e-1"

      #   # Screenshots
      #   ",Print,exec,${a_launch_prefix} hyprshot -m output -o ~/Pictures/Screenshots -- imv"
      #   "ALT,Print,exec,${a_launch_prefix} hyprshot -m window -o ~/Pictures/Screenshots -- imv"
      #   "CTRL,Print,exec,${a_launch_prefix} hyprshot -m region -o ~/Pictures/Screenshots -- imv"

      #   # Switch workspaces with main_mod  + [0-9]
      #   "$main_mod ,1,workspace,1"
      #   "$main_mod ,2,workspace,2"
      #   "$main_mod ,3,workspace,3"
      #   "$main_mod ,4,workspace,4"
      #   "$main_mod ,5,workspace,5"
      #   "$main_mod ,6,workspace,6"
      #   "$main_mod ,7,workspace,7"
      #   "$main_mod ,8,workspace,8"
      #   "$main_mod ,9,workspace,9"
      #   "$main_mod ,10,workspace,0"

      #   # Move active window to a workspace with main_mod  + SHIFT + [0-9]
      #   "$main_mod  SHIFT,1,movetoworkspace,1"
      #   "$main_mod  SHIFT,2,movetoworkspace,2"
      #   "$main_mod  SHIFT,3,movetoworkspace,3"
      #   "$main_mod  SHIFT,4,movetoworkspace,4"
      #   "$main_mod  SHIFT,5,movetoworkspace,5"
      #   "$main_mod  SHIFT,6,movetoworkspace,6"
      #   "$main_mod  SHIFT,7,movetoworkspace,7"
      #   "$main_mod  SHIFT,8,movetoworkspace,8"
      #   "$main_mod  SHIFT,9,movetoworkspace,9"
      #   "$main_mod  SHIFT,10,movetoworkspace,10"

      # ];
      # binde = [
      #   # Resize windows
      #   "$main_mod  ALT,H,resizeactive,-5% 0"
      #   "$main_mod  ALT,L,resizeactive,5% 0"
      #   "$main_mod  ALT,J,resizeactive,0 5%"
      #   "$main_mod  ALT,K,resizeactive,0 -5%"
      # ];
      # bindel = [
      #   # Multimedia keys for volume and brightness
      #   ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      #   ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      #   ",XF86AudioMute,exec,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      #   ",XF86AudioMicMute,exec,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      #   ",XF86MonBrightnessUp,exec,brightnessctl set +4%"
      #   ",XF86MonBrightnessDown,exec,brightnessctl set 4%-"
      #   ",XF86AudioNext,exec,mpc next" # Or `playerctl --all-players next`
      #   ",XF86AudioPrev,exec,mpc prev" # Or `playerctl --all-players previous`
      #   ",XF86AudioPlay,exec,mpc toggle" # Or `playerctl --all-players play-pause`
      #   ",XF86AudioStop,exec,mpc stop" # Or `playerctl --all-players stop`
      # ];
      # bindl = [
      #   "$main_mod ,Z,exec,loginctl lock-session"
      #   "$main_mod  CTRL SHIFT,Q,exec,loginctl terminate-user $USER" # Logout & Exit Hyprland
      #   "$main_mod  CTRL SHIFT,W,exec,systemctl suspend" # Suspend
      #   "$main_mod  CTRL SHIFT,E,exec,systemctl hibernate" # Hibernate
      #   "$main_mod  CTRL SHIFT,R,exec,systemctl reboot" # Reboot
      #   "$main_mod  CTRL SHIFT,T,exec,systemctl poweroff" # Shutdown
      #   ",switch:Lid Switch,exec,loginctl lock-session" # Lock when lid switch triggered
      # ];
      # bindm = [
      #   # LMB/RMB and dragging to move/resize windows
      #   "$main_mod ,mouse:272,movewindow"
      #   "$main_mod ,mouse:273,resizewindow"
      # ];
      # windowrule = [
      #   "match:class ^imv$,float true"
      #   "match:class ^org\\.pulseaudio\\.pavucontrol$,float true"
      #   "match:class ^thunar$, match:title ^File Operation Progress$,float true"
      #   "match:class ^xdg-desktop-portal-gtk$,float true"
      #   "match:class ^yad$,float true"

      #   "match:class ^firefox|google-chrome$,idle_inhibit focus"
      #   "match:tag video_pip,float true,pin true,size 480 270,move 100%-w-5 100%-w-5"
      #   # Firefox PiP
      #   "match:initial_class ^firefox$,match:initial_title ^Picture-in-Picture$,tag +video_pip"
      #   "match:initial_title ^Picture\\ in\\ picture$,tag +video_pip" # Chrome PiP

      #   "match:class ^anki$,match:title ^HyperTTS: Add Audio \\(Collection\\)$,float true"
      #   "match:class ^anki$,match:title ^HyperTTS: Add Audio \\(Collection\\)$,size 1090 640"

      #   "match:class ^org\\.inkscape\\.Inkscape$,match:title ^Function Plotter$,float true"
      #   "match:class ^org\\.inkscape\\.Inkscape$,match:title ^Function Plotter$,float true"

      #   # Game
      #   "match:tag game,fullscreen true,immediate true"
      #   "match:tag game,no_anim true,no_blur true,no_shadow true"
      #   "match:tag game,opacity 1,border_size 1,rounding 0"
      #   # Steam Proton Games
      #   "match:initial_class ^steam_app_\\d+$,match:initial_title negative:^(?i)(.*Launcher.*)$,tag +game"

      #   # Previewer
      #   "match:tag previewer,float true,no_initial_focus true,opaque true"
      #   "match:initial_class ^(ueberzugpp_.*),tag +previewer"
      #   # "match:initial_class ^Qemu-system-x86_64$,float true"
      # ];
    };
  };
  # For dbus' loginctl lock/unlock
  services.hypridle = let
    locking_utility =
      if config.programs.hyprlock.enable
      then lib.getExe config.programs.hyprlock.package
      else lib.getExe config.programs.swaylock.package; # Default to swaylock
  in {
    enable = true;
    settings = {
      general = {
        lock_cmd = lib.mkDefault "pidof ${locking_utility} || (${locking_utility} && loginctl unlock-session)";
        before_sleep_cmd = "loginctl lock-session"; # lock before suspend.
        after_sleep_cmd = "hyprctl dispatch dpms on"; # avoid have to press a key twice to turn on the display.
      };
      listener = [
        {
          timeout = 600; # 10min
          on-timeout = "loginctl lock-session"; # lock screen when timeout has passed
        }
        {
          timeout = 630; # 10.5min
          on-timeout = "hyprctl dispatch dpms off"; # screen off when timeout has passed
          on-resume = "hyprctl dispatch dpms on"; # screen on when activity is detected after timeout has fired.
        }
      ];
    };
  };
  programs.hyprlock.enable = false;
  programs.swaylock.enable =
    if config.programs.hyprlock.enable
    then false
    else true;
  home.pointerCursor.hyprcursor.enable = true;
  services.cliphist.enable = true;
}

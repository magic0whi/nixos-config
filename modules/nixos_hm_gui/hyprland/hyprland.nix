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
      main_mod._var = "SUPER";
      launch_prefix._var = "systemd-run --user --scope --";
      terminal.var = lib.getExe config.xdg.terminal-exec.package;
      # menu._var = "rofi -show combi";
      menu._var = config.programs.anyrun.menu_script;
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
      file_manager._var = ''terminal .. "yazi"'';
      wlogout._var = config.programs.wlogout.wrapper_script;
      # This will get rid of the pixelated look, but will not scale applications properly. To do this, each toolkit has
      # its own mechanism.
      xwayland.force_zero_scaling = true;
      config = {
        general = {
          border_size = 2;
          gaps_in = 2; # gaps between windows
          gaps_out = 5; # gaps between windows and monitor edges
          col = {
            active_border = "rgba(33ccffee) rgba(00ff99ee) 45deg";
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
              (mkLuaInline ''mainMod .. " + E"'')
              (mkLuaInline ''hl.dsp.exec_cmd(launch_prefix .. file_manager)'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + Q"'')
              (mkLuaInline "hl.dsp.exec_cmd(launch_prefix .. terminal)")
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + SPACE"'')
              (mkLuaInline "hl.dsp.exec_cmd(launch_prefix .. menu)")
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + V"'')
              (mkLuaInline "hl.dsp.exec_cmd(launch_prefix .. clip_manager)")
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + CTRL + "'')
              (mkLuaInline "hl.dsp.exec_cmd(launch_prefix .. colorpicker)")
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + X"'')
              (mkLuaInline "hl.dsp.exec_cmd(launch_prefix .. wlogout)")
            ];
          }

          # Window management
          {
            _args = [
              (mkLuaInline ''mainMod .. " + W"'')
              (mkLuaInline "hl.dsp.window.close()")
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + F"'')
              (mkLuaInline "hl.dsp.window.fullscreen()")
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + SHIFT + F"'')
              (mkLuaInline ''hl.dsp.window.float({ action = "toggle" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + G"'')
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
              (mkLuaInline ''mainMod .. " + T"'')
              (mkLuaInline ''hl.dsp.layout("togglesplit")'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + SHIFT + P"'')
              (mkLuaInline "hl.dsp.window.pseudo()")
            ];
          }

          # Special Workspace (Scratchpad)
          {
            _args = [
              (mkLuaInline ''mainMod .. " + S"'')
              (mkLuaInline ''hl.dsp.workspace.toggle_special("magic")'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + SHIFT + S"'')
              (mkLuaInline ''hl.dsp.window.move({ workspace = "special:magic" })'')
            ];
          }

          # Focus Movement
          {
            _args = [
              (mkLuaInline ''mainMod .. " + H"'')
              (mkLuaInline ''hl.dsp.focus({ direction = "l" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + J"'')
              (mkLuaInline ''hl.dsp.focus({ direction = "d" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + K"'')
              (mkLuaInline ''hl.dsp.focus({ direction = "u" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + L"'')
              (mkLuaInline ''hl.dsp.focus({ direction = "r" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + N"'')
              (mkLuaInline ''hl.dsp.window.cycle_next()'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + P"'')
              (mkLuaInline ''hl.dsp.window.cycle_next({ next = false })'')
            ];
          }

          # Move Windows
          {
            _args = [
              (mkLuaInline ''mainMod .. " + SHIFT + H"'')
              (mkLuaInline ''hl.dsp.window.move({ direction = "l" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + SHIFT + J"'')
              (mkLuaInline ''hl.dsp.window.move({ direction = "d" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + SHIFT + K"'')
              (mkLuaInline ''hl.dsp.window.move({ direction = "u" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + SHIFT + L"'')
              (mkLuaInline ''hl.dsp.window.move({ direction = "r" })'')
            ];
          }

          # Workspace Scrolling
          {
            _args = [
              (mkLuaInline ''mainMod .. " + mouse_down"'')
              (mkLuaInline ''hl.dsp.focus({ workspace = "e+1" })'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + mouse_up"'')
              (mkLuaInline ''hl.dsp.focus({ workspace = "e-1" })'')
            ];
          }

          # Screenshots
          {
            _args = [
              (mkLuaInline ''"Print"'')
              (mkLuaInline
                ''hl.dsp.exec_cmd(launch_prefix .. "hyprshot -m output -o ~/Pictures/Screenshots -- imv")'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''"ALT + Print"'')
              (mkLuaInline
                ''hl.dsp.exec_cmd(launch_prefix .. "hyprshot -m window -o ~/Pictures/Screenshots -- imv")'')
            ];
          }
          {
            _args = [
              (mkLuaInline ''"CTRL + Print"'')
              (mkLuaInline
                ''hl.dsp.exec_cmd(launch_prefix .. "hyprshot -m region -o ~/Pictures/Screenshots -- imv")'')
            ];
          }

          # Window Resizing (Repeating)
          {
            _args = [
              (mkLuaInline ''mainMod .. " + ALT + H"'')
              (mkLuaInline ''hl.dsp.window.resize({ x = -.05, y = 0, relative = true })'')
              {repeating = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + ALT + L"'')
              (mkLuaInline ''hl.dsp.window.resize({ x = .05, y = 0, relative = true })'')
              {repeating = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + ALT + J"'')
              (mkLuaInline ''hl.dsp.window.resize({ x = 0, y = .05, relative = true })'')
              {repeating = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + ALT + K"'')
              (mkLuaInline ''hl.dsp.window.resize({ x = 0, y = -.05, relative = true })'')
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
              (mkLuaInline ''mainMod .. " + Z"'')
              (mkLuaInline ''hl.dsp.exec_cmd("loginctl lock-session")'')
              {locked = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + CTRL + SHIFT + Q"'')
              (mkLuaInline ''hl.dsp.exec_cmd("loginctl terminate-user $USER")'')
              {locked = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + CTRL + SHIFT + W"'')
              (mkLuaInline ''hl.dsp.exec_cmd("systemctl suspend")'')
              {locked = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + CTRL + SHIFT + E"'')
              (mkLuaInline ''hl.dsp.exec_cmd("systemctl hibernate")'')
              {locked = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + CTRL + SHIFT + R"'')
              (mkLuaInline ''hl.dsp.exec_cmd("systemctl reboot")'')
              {locked = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + CTRL + SHIFT + T"'')
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
              (mkLuaInline ''mainMod .. " + mouse:272"'')
              (mkLuaInline "hl.dsp.window.drag()")
              {mouse = true;}
            ];
          }
          {
            _args = [
              (mkLuaInline ''mainMod .. " + mouse:273"'')
              (mkLuaInline "hl.dsp.window.resize()")
              {mouse = true;}
            ];
          }
        ]
        ++ (builtins.concatLists (builtins.genList (
            i: [
              {
                _args = [
                  (lib.generators.mkLuaInline ''mainMod .. " + ${toString i}"'')
                  (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = ${toString i} })")
                ];
              }
              {
                _args = [
                  (lib.generators.mkLuaInline ''mainMod .. " + SHIFT + ${toString i}"'')
                  (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = ${toString i} })")
                ];
              }
            ]
          )
          10));

      # bind = [
      #   "$mainMod,E,exec,${launch_prefix} $file_manager"
      #   "$mainMod,Q,exec,${launch_prefix} $terminal"
      #   "$mainMod,SPACE,exec,${launch_prefix} $menu"
      #   "$mainMod,V,exec,${launch_prefix} $clip_manager"
      #   "$mainMod CTRL,P,exec,${launch_prefix} $colorpicker"
      #   "$mainMod,X,exec,${launch_prefix} $wlogout"
      #   "$mainMod,W,killactive,"
      #   "$mainMod,F,fullscreen,"
      #   "$mainMod SHIFT,F,togglefloating"
      #   "$mainMod,G,exec,hyprctl dispatch setfloating && hyprctl dispatch pin"
      #   "$mainMod,T,layoutmsg,togglesplit" # dwindle
      #   "$mainMod SHIFT,P,pseudo" # dwindle"

      #   # Special workspace (scratchpad)
      #   "$mainMod,S,togglespecialworkspace,magic"
      #   "$mainMod SHIFT,S,movetoworkspace,special:magic"

      #   # Move focus
      #   "$mainMod,H,movefocus,l"
      #   "$mainMod,J,movefocus,d"
      #   "$mainMod,K,movefocus,u"
      #   "$mainMod,L,movefocus,r"
      #   "$mainMod,N,cyclenext,"
      #   "$mainMod,P,cyclenext,prev"

      #   # Move windows
      #   "$mainMod SHIFT,H,movewindow,l"
      #   "$mainMod SHIFT,J,movewindow,d"
      #   "$mainMod SHIFT,K,movewindow,u"
      #   "$mainMod SHIFT,L,movewindow,r"

      #   # Scroll through existing workspaces with mainMod + scroll
      #   "$mainMod,mouse_down,workspace,e+1"
      #   "$mainMod,mouse_up,workspace,e-1"

      #   # Screenshots
      #   ",Print,exec,${launch_prefix} hyprshot -m output -o ~/Pictures/Screenshots -- imv"
      #   "ALT,Print,exec,${launch_prefix} hyprshot -m window -o ~/Pictures/Screenshots -- imv"
      #   "CTRL,Print,exec,${launch_prefix} hyprshot -m region -o ~/Pictures/Screenshots -- imv"

      #   # Switch workspaces with mainMod + [0-9]
      #   "$mainMod,0,workspace,0"
      #   "$mainMod,1,workspace,1"
      #   "$mainMod,2,workspace,2"
      #   "$mainMod,3,workspace,3"
      #   "$mainMod,4,workspace,4"
      #   "$mainMod,5,workspace,5"
      #   "$mainMod,6,workspace,6"
      #   "$mainMod,7,workspace,7"
      #   "$mainMod,8,workspace,8"
      #   "$mainMod,9,workspace,9"

      #   # Move active window to a workspace with mainMod + SHIFT + [0-9]
      #   "$mainMod SHIFT,0,movetoworkspace,0"
      #   "$mainMod SHIFT,1,movetoworkspace,1"
      #   "$mainMod SHIFT,2,movetoworkspace,2"
      #   "$mainMod SHIFT,3,movetoworkspace,3"
      #   "$mainMod SHIFT,4,movetoworkspace,4"
      #   "$mainMod SHIFT,5,movetoworkspace,5"
      #   "$mainMod SHIFT,6,movetoworkspace,6"
      #   "$mainMod SHIFT,7,movetoworkspace,7"
      #   "$mainMod SHIFT,8,movetoworkspace,8"
      #   "$mainMod SHIFT,9,movetoworkspace,9"

      # ];
      # binde = [
      #   # Resize windows
      #   "$mainMod ALT,H,resizeactive,-5% 0"
      #   "$mainMod ALT,L,resizeactive,5% 0"
      #   "$mainMod ALT,J,resizeactive,0 5%"
      #   "$mainMod ALT,K,resizeactive,0 -5%"
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
      #   "$mainMod,Z,exec,loginctl lock-session"
      #   "$mainMod CTRL SHIFT,Q,exec,loginctl terminate-user $USER" # Logout & Exit Hyprland
      #   "$mainMod CTRL SHIFT,W,exec,systemctl suspend" # Suspend
      #   "$mainMod CTRL SHIFT,E,exec,systemctl hibernate" # Hibernate
      #   "$mainMod CTRL SHIFT,R,exec,systemctl reboot" # Reboot
      #   "$mainMod CTRL SHIFT,T,exec,systemctl poweroff" # Shutdown
      #   ",switch:Lid Switch,exec,loginctl lock-session" # Lock when lid switch triggered
      # ];
      # bindm = [
      #   # LMB/RMB and dragging to move/resize windows
      #   "$mainMod,mouse:272,movewindow"
      #   "$mainMod,mouse:273,resizewindow"
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

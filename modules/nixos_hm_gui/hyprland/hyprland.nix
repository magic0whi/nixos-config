{
  lib,
  pkgs,
  ...
}:
let
  hypr_pkg = pkgs.hyprland;
in
{
  # NOTE: this executable is used by Greetd to start a wayland session when system boot up. With such a
  # vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config in NixOS
  # module
  # home.file.".wayland-session".source = "${hypr_pkg}/bin/start-hyprland"; # TODO niri debug
  catppuccin.hyprland.enable = false;

  wayland.windowManager.hyprland = {
    enable = true;
    package = hypr_pkg;
    settings = {
      # Variables
      main_mod._var = "SUPER";
      curve = [
        {
          # https://easings.net/#easeOutQuint
          _args = [
            "easeOutQuint"
            {
              type = "bezier";
              points = [
                [
                  0.23
                  1
                ]
                [
                  0.32
                  1
                ]
              ];
            }
          ];
        }
        {
          # https://cubic-bezier.com/#0,0,1,1
          _args = [
            "linear"
            {
              type = "bezier";
              points = [
                [
                  0
                  0
                ]
                [
                  1
                  1
                ]
              ];
            }
          ];
        }
        {
          # https://cubic-bezier.com/#.5,.5,.75,1
          _args = [
            "almostLinear"
            {
              type = "bezier";
              points = [
                [
                  0.5
                  0.5
                ]
                [
                  0.75
                  1.0
                ]
              ];
            }
          ];
        }
        {
          # https://cubic-bezier.com/#.15,0,.1,1
          _args = [
            "quick"
            {
              type = "bezier";
              points = [
                [
                  0.15
                  0
                ]
                [
                  0.1
                  1
                ]
              ];
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
      bind =
        with lib.generators;
        [
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

          # System controls (Locked)
          {
            _args = [
              (mkLuaInline ''main_mod  .. " + Z"'')
              (mkLuaInline ''hl.dsp.exec_cmd("loginctl lock-session")'')
              { locked = true; }
            ];
          }
          {
            _args = [
              (mkLuaInline ''"CTRL + ALT + Delete"'')
              (mkLuaInline ''hl.dsp.exec_cmd("loginctl terminate-user $USER")'')
              { locked = true; }
            ];
          }
        ]
        ++ (builtins.concatLists (
          builtins.genList (
            i:
            let
              ws_num = if i == 0 then 10 else i;
            in
            [
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
          ) 10
        ));
      window_rule = [
        ## Windows That Better Float
        {
          match.class = "^(${
            builtins.concatStringsSep "|" [
              "imv"
              ''org\.pulseaudio\.pavucontrol''
              "yad"
            ]
          })$";
          float = true;
        }
        # Inkscape
        {
          match = {
            class = "^org\\.inkscape\\.Inkscape$";
            title = "^Function Plotter$";
          };
          float = true;
        }

        ## Pop-up Windows
        {
          match = {
            class = "^thunar$";
            title = "^File Operation Progress$";
          };
          float = true;
        }
        # Screensharing (xdg-desktop-portal-hyprland)
        {
          match.title = "^Select what to share$";
          float = true;
        }
        # Browsers
        {
          match.class = "^firefox|google-chrome$";
          idle_inhibit = "focus";
          opaque = true;
        }

        ## Video Picture-in-Picture
        {
          match.tag = "video_pip";
          float = true;
          pin = true;
          size = "480 270";
          move = "100%-w-5 100%-w-5";
        }
        # Firefox PiP
        {
          match = {
            initial_class = "^firefox$";
            initial_title = "^Picture-in-Picture$";
          };
          tag = "+video_pip";
        }
        # Chrome PiP
        {
          match.initial_title = "^Picture\\ in\\ picture$";
          tag = "+video_pip";
        }

        # Anki
        {
          match = {
            class = "^anki$";
            title = "^HyperTTS: Add Audio \\(Collection\\)$";
          };
          float = true;
          size = "1090 640";
        }

        # Games
        {
          match.tag = "game";
          border_size = 1;
          fullscreen = true;
          immediate = true;
          no_anim = true;
          no_blur = true;
          no_shadow = true;
          opacity = 1;
          rounding = 0;
        }
        {
          match = {
            initial_class = ''^steam_app_\d+$'';
            initial_title = "negative:^(?i)(.*Launcher.*)$";
          };
          tag = "+game";
        }

        # Previewer
        {
          match.tag = "previewer";
          float = true;
          no_initial_focus = true;
          opaque = true;
        }
        {
          match.initial_class = "^(ueberzugpp_.*)";
          tag = "+previewer";
        }
      ];
    };
  };
  home.pointerCursor.hyprcursor.enable = true;
}

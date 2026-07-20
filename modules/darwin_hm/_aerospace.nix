{ config, ... }:
{
  programs.aerospace = {
    enable = true;
    launchd.enable = true;
    # Ref https://nikitabobko.github.io/AeroSpace/guide#configuring-aerospace
    settings = {
      automatically-unhide-macos-hidden-apps = true; # Turn off macOS "Hide application" (<cmd-h>) feature
      exec.inherit-env-vars = true;
      gaps = {
        inner.horizontal = 3;
        inner.vertical = 3;
        outer.left = 3;
        outer.bottom = 3;
        outer.top = 3;
        outer.right = 3;
      };
      mode =
        let
          mod = "cmd";
        in
        {
          main.binding = {
            # Run terminal
            "${mod}-q" = "exec-and-forget osascript -lJavaScript ${config.xdg.configHome}/aerospace/ghostty-actions.js 3";
            "${mod}-shift-q" = "exec-and-forget osascript -lJavaScript ${config.xdg.configHome}/aerospace/ghostty-actions.js 2";
            "${mod}-alt-q" = "exec-and-forget osascript -lJavaScript ${config.xdg.configHome}/aerospace/ghostty-actions.js 1";

            # Run Finder
            "${mod}-alt-e" = "exec-and-forget osascript -lJavaScript ${config.xdg.configHome}/aerospace/finder-actions.js 2";
            "${mod}-shift-e" = "exec-and-forget osascript -lJavaScript ${config.xdg.configHome}/aerospace/finder-actions.js 1";

            "${mod}-alt-w" = "close";

            # Ref: https://nikitabobko.github.io/AeroSpace/commands#layout
            "${mod}-slash" = "layout tiles horizontal vertical";
            "${mod}-quote" = "layout accordion horizontal vertical";

            # Move focus, see: https://nikitabobko.github.io/AeroSpace/commands#focus
            "${mod}-h" = "focus left";
            "${mod}-j" = "focus down";
            "${mod}-k" = "focus up";
            "${mod}-l" = "focus right";
            "${mod}-tab" = "workspace-back-and-forth";
            "${mod}-alt-n" = "workspace --wrap-around next"; # Conflict with KeePassXC's cmd-n
            "${mod}-alt-p" = "workspace --wrap-around prev";

            # Move windows, see: https://nikitabobko.github.io/AeroSpace/commands#move
            "${mod}-shift-h" = "move left";
            "${mod}-shift-j" = "move down";
            "${mod}-shift-k" = "move up";
            "${mod}-shift-l" = "move right";

            # Resize windows, See: https://nikitabobko.github.io/AeroSpace/commands#resize
            "${mod}-alt-minus" = "resize smart -50";
            "${mod}-alt-equal" = "resize smart +50";
            "${mod}-shift-r" = "mode resize";

            # Switch workpaces, see: https://nikitabobko.github.io/AeroSpace/commands#workspace
            "${mod}-1" = "workspace 1";
            "${mod}-2" = "workspace 2";
            "${mod}-3" = "workspace 3";
            "${mod}-4" = "workspace 4";
            "${mod}-5" = "workspace 5";
            "${mod}-6" = "workspace 6";
            "${mod}-7" = "workspace 7";
            "${mod}-8" = "workspace 8";
            "${mod}-9" = "workspace 9";
            "${mod}-0" = "workspace 0";

            # Move active window to a workspace
            "${mod}-shift-1" = "move-node-to-workspace 1";
            "${mod}-shift-2" = "move-node-to-workspace 2";
            "${mod}-shift-3" = "move-node-to-workspace 3";
            "${mod}-shift-4" = "move-node-to-workspace 4";
            "${mod}-shift-5" = "move-node-to-workspace 5";
            "${mod}-shift-6" = "move-node-to-workspace 6";
            "${mod}-shift-7" = "move-node-to-workspace 7";
            "${mod}-shift-8" = "move-node-to-workspace 8";
            "${mod}-shift-9" = "move-node-to-workspace 9";
            "${mod}-shift-0" = "move-node-to-workspace 0";

            "${mod}-shift-semicolon" = "mode service"; # Ref: https://nikitabobko.github.io/AeroSpace/commands#mode
          };
          # Ref: https://nikitabobko.github.io/AeroSpace/guide#binding-modes
          service.binding = {
            esc = [
              "reload-config"
              "mode main"
            ];

            # Toggle between floating and tiling layout
            f = [
              "layout floating tiling"
              "mode main"
            ];

            # reset layout
            r = [
              "flatten-workspace-tree"
              "mode main"
            ];

            backspace = [
              "close-all-windows-but-current"
              "mode main"
            ];

            "${mod}-shift-h" = [
              "join-with left"
              "mode main"
            ];
            "${mod}-shift-j" = [
              "join-with down"
              "mode main"
            ];
            "${mod}-shift-k" = [
              "join-with up"
              "mode main"
            ];
            "${mod}-shift-l" = [
              "join-with right"
              "mode main"
            ];
          };
          resize.binding = {
            h = "resize width -50";
            j = "resize height +50";
            k = "resize height -50";
            l = "resize width +50";
            enter = "mode main";
            esc = "mode main";
          };
        };
      workspace-to-monitor-force-assignment = {
        "1" = [ "Built-in Retina Display" ];
        "2" = [ "Built-in Retina Display" ];
        "3" = [ "Built-in Retina Display" ];
        "4" = [ "Built-in Retina Display" ];
      };
      on-window-detected = [
        {
          "if".app-id = "io.mpv";
          run = [ "layout floating" ];
        }
        {
          "if".app-id = "com.valvesoftware.steam";
          run = [ "layout tiling" ];
        }
      ];
    };
  };
}

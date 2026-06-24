{
  lib,
  pkgs,
  const,
  ...
}:
{
  wayland.windowManager.niri.extraConfig =
    # Reorder workspaces
    ''
      // =========================== spawn-at-startup.kdl =================================
      spawn-at-startup "${
        pkgs.writeShellScript "reorder-workspaces.sh" (
          lib.concatLines (
            builtins.genList (
              i:
              let
                idx = toString i;
                ws_name = builtins.elemAt const.workspaces i;
              in
              ''niri msg action move-workspace-to-index ${idx} --reference "${ws_name}"''
            ) 10
          )
        )
      }"
    ''
    + ''
      // TIP: `/-` comments out the whole node.
      input {
        touchpad {
          tap // tap-to-click
          dwt // disable-when-typing.
          natural-scroll // inverts the scrolling direction.
        }
      }

      // Clients will be informed that they are tiled, removing some client-side rounded corners and window frame.
      // After enabling or disabling this, you need to restart the apps for this to take effect.
      //
      // By default focus border are rendered as a solid background rectangle behind windows. This is because windows using
      // client-side decorations can have an arbitrary shape.
      //
      // Niri will draw focus ring and border *around* windows that agree to omit their client-side decorations.
      //
      // Alternatively, you can override it with a window rule called `draw-border-with-background`.
      prefer-no-csd

      layout {
        gaps 8 // In logical pixels.
        focus-ring {
          // off
          width 4
          active-gradient from="#e5989b" to="#ffb4a2" angle=45 in="oklch longer hue"
          // The focus ring only draws around the active window, so the only place where you can see its inactive-color
          //is on other monitors.
          inactive-color "#595959aa"
        }
        shadow { on; } // shadows increase visibility on floating window
      }

      window-rule {
        geometry-corner-radius 20 // Rounded logical corners
        clip-to-geometry true // Clips window contents to the rounded corner boundaries.
      }

      hotkey-overlay {
        skip-at-startup //disable the "Important Hotkeys" pop-up at startup.
        hide-not-bound
      }

      screenshot-path null // Disable saving screenshots to disk.

      // https://niri-wm.github.io/niri/Configuration%3A-Animations.html
      // TODO
      // animations { }
      // ==================================================================================
    '';
}

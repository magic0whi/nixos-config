{
  const,
  lib,
  omniwmLib,
  ...
}:
let
  ctrl = "Control";
  mod = "Command";
  alt = "Option";
in
{
  programs.omniwm = {
    enable = true;
    launchd.enable = true;

    # Entries under these paths would be kept during the activation config file
    # generating.
    preserveSettings = [
      "routing"
      "shellPermissions"
      "workspaceBar.iconOverrides"
    ];

    # Merged over the packaged version's own default settings.toml, so only the
    # changed keys are listed here.
    settings = {
      general = {
        updateChecksEnabled = false;
        # OmniWM's springs are `dampingRatio 1.0, stiffness 800`; niri's focus ring uses
        # `damping-ratio 0.937 stiffness 323`. The speed multiplies stiffness by speed², so
        # 0.65 lands on 800 × 0.65² ≈ 338 — niri's settle time. Damping stays 1.0, so this
        # softens and lengthens the motion but cannot add niri's slight overshoot.
        animationSpeed = 0.65;
      };
      clipboard.historyEnabled = true;
      focus = {
        crossesMonitorAtEdge = true;
        moveCrossesMonitorAtEdge = true;
      };

      # OmniWM has no one-shot pause: it resumes on the same shortcut, on "Leave Keyboard Mode",
      # or when this timer runs out. Keep it short so one chord gets through and the WM re-arms.
      keyboardModes.pauseTimeoutSeconds = 1.0;

      gaps.size = 8.0;
      borders = {
        width = 4.0;
        color = omniwmLib.colors.fromHex "#89b4fa";
        gradient = {
          enabled = true;
          direction = "topLeftToBottomRight";
          # niri fakes a rainbow with "oklch longer hue", which walks the long
          # way round the hue wheel. OmniWM lerps sRGB between two stops, so
          # nearby hues read as one flat colour; pick two far enough color to
          # show the travel.
          start = omniwmLib.colors.fromHex "#89b4fa";
          end = omniwmLib.colors.fromHex "#f5c2e7";
        };
      };

      workspaces = omniwmLib.workspaces (
        lib.imap0 (i: displayName: {
          inherit displayName;
          monitorAssignment.type = if i < 5 then "main" else "secondary";
        }) const.workspaces
      );

      hotkeys = omniwmLib.hotkeys (
        {
          closeFocusedWindow = "${mod}+W";
          toggleContainerFullPrimarySpan = "${mod}+F";
          toggleFullscreen = "${mod}+Shift+F";
          toggleFloatingFocus = "${mod}+T";
          toggleFocusedWindowFloating = "${mod}+Shift+T";

          # Focus. niri: Mod+H/J/K/L. J/K are niri's `-window-or-workspace-` variants: they stay
          # inside the column and only change workspace at its edge. H/L's `-or-monitor-` half
          # comes from `focus.crossesMonitorAtEdge` above.
          "focus.left" = "${mod}+H";
          focusWindowOrWorkspaceDown = "${mod}+J";
          focusWindowOrWorkspaceUp = "${mod}+K";
          "focus.right" = "${mod}+L";
          focusColumnFirst = "${mod}+Home";
          focusColumnLast = "${mod}+End";

          # Move
          "move.left" = "${mod}+Shift+H";
          moveWindowDownOrToWorkspaceDown = "${mod}+Shift+J";
          moveWindowUpOrToWorkspaceUp = "${mod}+Shift+K";
          "move.right" = "${mod}+Shift+L";
          moveColumnToFirst = "${mod}+Shift+Home";
          moveColumnToLast = "${mod}+Shift+End";

          centerVisibleColumns = "${mod}+C";
          toggleColumnTabbed = "${mod}+D";
          consumeWindowIntoColumn = "${mod}+Comma";
          expelWindowFromColumn = "${mod}+Period";
          # niri's Mod+[ / Mod+] `consume-or-expel-window-*` is unassignable in OmniWM.

          # Hands the next chord to the focused app, workaround for the Cmd key
          toggleShortcutPause = "${mod}+${alt}+P";

          # Sizing
          cycleSizeForward = "${mod}+R";
          cycleSizeBackward = "${ctrl}+${mod}+R";
          cycleWindowSecondarySpanForward = "${mod}+Shift+R";
          resetWindowSecondarySpan = "${ctrl}+${mod}+Shift+R";
          "resizeContainerPrimarySpan.shrink" = "${mod}+Minus";
          "resizeContainerPrimarySpan.grow" = "${mod}+Equal";
          "resizeWindowSecondarySpan.shrink" = "${mod}+Shift+Minus";
          "resizeWindowSecondarySpan.grow" = "${mod}+Shift+Equal";
          expandContainerToAvailablePrimarySpan = "${ctrl}+${mod}+F";

          # Workspaces
          "switchWorkspace.next" = "${mod}+N";
          "switchWorkspace.previous" = "${mod}+P";
          moveColumnToWorkspaceDown = "${mod}+Shift+N";
          moveColumnToWorkspaceUp = "${mod}+Shift+P";

          "openCommandPalette.applications" = "${mod}+Space";
          "openCommandPalette.clipboard" = "${mod}+V";
          "openApp.com.mitchellh.ghostty" = "${mod}+Q";
          # Finder here, since OmniWM shortcuts cannot spawn a command.
          "openApp.com.apple.finder" = "${mod}+E";

          # AeroSpace bound `cmd-/` to cycling layouts
          toggleWorkspaceLayout = "${mod}+Slash";

          # Disable due to conflict with cycleWindowSecondarySpanForward, default
          # "Option+Shift+R"
          raiseAllFloatingWindows = "Unassigned";
        }
        // lib.listToAttrs (
          lib.concatMap (i: [
            (lib.nameValuePair "switchWorkspace.${i}" "${mod}+${i}")
            (lib.nameValuePair "moveToWorkspace.${i}" "${mod}+Shift+${i}")
            (lib.nameValuePair "moveColumnToWorkspace.${i}" "${ctrl}+${mod}+${i}")
          ]) (map toString (lib.range 0 9))
        )
        # Disable due to conflict with moveColumnToWorkspace, default "Control+Option+${i}"
        // lib.listToAttrs (map (i: lib.nameValuePair "focusColumn.${i}" "Unassigned") (map toString (lib.range 0 8)))
      );
    };
  };
}

{
  config,
  const,
  lib,
  pkgs,
  omniwmLib,
  ...
}:
let
  ctrl = "Control";
  mod = "Command";
  alt = "Option";

  # The bar layout, profile overrides and per-widget options live in
  # ~/.config/omniwm/shell/shell.toml, which OmniWM also rewrites for edits
  # made in Settings > Styles & Widgets. Deploy it as a writable copy from
  # here, like `settings.toml`, so GUI edits last until this file changes.
  shell_settings = (pkgs.formats.toml { }).generate "omniwm-shell.toml" {
    profile = "default";
    profiles.default = {
      theme = "catppuccin";
      leading = [
        "app-menu"
        "clock"
        "system-stats"
        "media"
        "active-window"
      ];
      center = [ "workspaces" ];
      trailing = [
        "notifications"
        "battery-details"
        "volume"
        "wifi"
        "control-center"
        "omniwm"
      ];
      workspaceBar = {
        hideEmptyWorkspaces = true;
        deduplicateAppIcons = true;
        showItemBackgrounds = true;
        transparentBackground = true;
      };
      widgets = {
        active-window.maxWidth = 250.0;
        battery-details.percent = "inside";
        clock.date = false;
        workspaces.indicator = "dots";
      };
    };
  };
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

      appRules =
        let
          to_ws =
            ws_name:
            let
              idx = lib.lists.findFirstIndex (name: name == ws_name) (-1) const.workspaces;
            in
            assert lib.assertMsg (idx >= 0) "omniwm: const.workspaces has no workspace named ${ws_name}";
            toString (idx + 1);
        in
        [
          # 1terminal
          (omniwmLib.appRule "com.mitchellh.ghostty" { assignToWorkspace = to_ws "1terminal"; })

          # 2browser
          (omniwmLib.appRule "org.mozilla.firefox" { assignToWorkspace = to_ws "2browser"; })
          (omniwmLib.appRule "com.google.Chrome" { assignToWorkspace = to_ws "2browser"; })

          # 3chat - niri matches Telegram by title because its Linux app-id differs
          (omniwmLib.appRule "ru.keepcoder.Telegram" { assignToWorkspace = to_ws "3chat"; })
          (omniwmLib.appRule "com.tencent.xinWeChat" { assignToWorkspace = to_ws "3chat"; })
          (omniwmLib.appRule "com.tencent.qq" { assignToWorkspace = to_ws "3chat"; })

          # 4gaming
          (omniwmLib.appRule "com.valvesoftware.steam" { assignToWorkspace = to_ws "4gaming"; })
          (omniwmLib.appRule "com.heroicgameslauncher.hgl" { assignToWorkspace = to_ws "4gaming"; })

          # 5music
          (omniwmLib.appRule "org.jeffvli.feishin" { assignToWorkspace = to_ws "5music"; })

          # 6file
          (omniwmLib.appRule "net.ankiweb.dtop" { assignToWorkspace = to_ws "6file"; })

          # 7design
          (omniwmLib.appRule "com.super-productivity.app" { assignToWorkspace = to_ws "7design"; })

          # 8vm - the macOS counterparts of qemu and virt-manager
          (omniwmLib.appRule "com.utmapp.UTM" { assignToWorkspace = to_ws "8vm"; })

          # 0other
        ];

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

          centerVisibleColumns = "${alt}+C";
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
          "openCommandPalette.clipboard" = "${alt}+V";
          "openApp.com.mitchellh.ghostty" = "${mod}+Q";
          # Finder here, since OmniWM shortcuts cannot spawn a command.
          "openApp.com.apple.finder" = "${mod}+E";

          # AeroSpace bound `cmd-/` to cycling layouts
          toggleWorkspaceLayout = "${mod}+Slash";

          # Disable due to conflict with cycleWindowSecondarySpanForward, default
          # "Option+Shift+R"
          raiseAllFloatingWindows = "Unassigned";
          # Default keybind Control+Option+Space conflict with IME switch
          openCommandPalette = "Unassigned";
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

  home.activation.omniwmShellSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="${config.xdg.configHome}/omniwm/shell/shell.toml"
    if ! ${pkgs.diffutils}/bin/cmp -s ${shell_settings} "$target" 2>/dev/null; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$target")"
      if [ -f "$target" ]; then
        $DRY_RUN_CMD cp -f "$target" "$target.bak"
      fi
      $DRY_RUN_CMD install -m 0644 ${shell_settings} "$target"
    fi
  '';

  # The bundled clock reserves "00:00 PM" so the bar does not jump between
  # times, which leaves a gap right of a 24-hour clock. A top-level widget
  # folder overrides the profile's copy; the reserve is the only change.
  xdg.configFile."omniwm/shell/widgets/clock/init.luau" = {
    force = true;
    text = ''
      -- SPDX-License-Identifier: GPL-2.0-only
      -- Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM
      -- Modified: reserve a 24-hour "00:00" instead of "00:00 PM".

      local look = require("../lib/look")
      local calendar = require("../lib/calendar")

      local function parts(ctx)
          local data = ctx.data
          local hour, minute, meridiem = string.match(string.gsub(data.clock, "\u{202F}", " "), "^(%d+)[:.](%d%d)%s*(%a*)$")
          if not hour then
              hour, minute, meridiem = os.date("%H"), os.date("%M"), ""
          end
          return { time = data.clock, date = data.date, hour = string.format("%02d", tonumber(hour)), minute = minute,
              meridiem = if meridiem ~= "" then string.lower(meridiem) else nil,
              showDate = ctx.select("settings", "date") ~= false, showIcon = ctx.select("settings", "icon") == true }
      end

      function render(ctx)
          local m = parts(ctx)
          local click = look.clockClick
          local behaviour = { onClick = click or ui.popout, onRightClick = if click then ui.popout else nil }
          local button = look.clockBar and look.clockBar(ctx, m)
          if not button then
              local scale = look.scale(ctx)
              local props = table.clone(behaviour)
              if ctx.data.bar.style.vertical then
                  props.gap = 0
                  props.pad = 2 * scale
                  if m.showIcon then
                      props[#props + 1] = look.glyph{ name = "calendar", size = 12 * scale }
                  end
                  props[#props + 1] = look.text{ text = m.hour, size = 11 * scale, weight = "medium" }
                  props[#props + 1] = look.text{ text = m.minute, size = 11 * scale }
                  if m.meridiem then
                      props[#props + 1] = look.text{ text = m.meridiem, size = 9 * scale, color = "secondaryForeground" }
                  end
              else
                  props.gap = 8 * scale
                  if m.showIcon then
                      props[#props + 1] = look.glyph{ name = "calendar", size = look.px(ctx, "symbol") }
                  end
                  if m.showDate then
                      props[#props + 1] = look.text{ text = m.date, size = 13 * scale, color = "secondaryForeground" }
                  end
                  props[#props + 1] = look.text{ text = m.time, size = 13 * scale, weight = "medium", reserve = "00:00" }
              end
              button = look.bar(ctx, props)
          end
          for key, value in behaviour do
              button[key] = value
          end
          return button
      end

      function popout(ctx)
          return calendar.popout(ctx)
      end
    '';
  };
}

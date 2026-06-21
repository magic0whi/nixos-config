{
  lib,
  const,
  pkgs,
  ...
}:
let
  spawn = args: builtins.concatStringsSep " " (map (s: ''"${s}"'') args);

  noctalia_prefix = spawn [
    "noctalia-shell"
    "ipc"
    "--any-display"
    "call"
  ];
in
{
  home.packages = [
    # Screenshot Annotation via satty
    (pkgs.writeShellApplication {
      name = "nirishot";
      runtimeInputs = [
        pkgs.grim
        pkgs.slurp
        pkgs.satty
        pkgs.wl-clipboard
      ];
      text = ''
        grim -t ppm -g "$(slurp -o -d -F monospace)" - \
        | satty \
          --filename - \
          --copy-command=wl-copy \
          --annotation-size-factor 2.0 \
          --actions-on-enter="save-to-clipboard,exit" \
          --brush-smooth-history-size=5 \
          --disable-notifications
      '';
    })
    # Simple script to pick color quickly
    (pkgs.writeShellApplication {
      name = "colorpicker";
      runtimeInputs = with pkgs; [
        hyprpicker # color picker
        imagemagick # Provides 'convert'
        libnotify # notify-send
      ];
      text = ''
        color=$(hyprpicker)
        image=/tmp/$color.png

        if [ -n "$color" ]; then
          echo "$color" | tr -d "\n" | wl-copy # Copy color code to clipboard
          convert -size 48x48 xc:"$color" "$image" # Generate preview
          # Notify about it
          notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$image" "$color, copied to clipboard."
        fi
      '';
    })
  ];
  wayland.windowManager.niri.extraConfig = ''
    // =========================== keybindings.kdl =================================
    switch-events {
      lid-close { spawn "${
        let
          NOCTALIA_PREFIX = "noctalia-shell ipc --any-display call toast send";
        in
        pkgs.writeShellScript "lid-close" ''
          MONITOR_COUNT=$(niri msg -j outputs | ${pkgs.jq}/bin/jq -e 'keys | length')
          if [ $MONITOR_COUNT -gt 1 ]; then
            ${NOCTALIA_PREFIX} '{"title": "Laptop lid closed", "body": "'"$MONITOR_COUNT"' monitors connected. Not locking.", "icon": "device-laptop-off"}'
          else
            ${NOCTALIA_PREFIX} '{"title": "Laptop lid closed", "body": "Session locked.", "icon": "device-laptop-off"}'
            loginctl lock-session
          fi
        ''
      }"; }
      lid-open  { spawn "${pkgs.writeShellScript "lid-open" ''
        noctalia-shell ipc --any-display call toast send '{"title": "The laptop lid is open!", "body": "TBD", "icon": "device-laptop"}'
      ''}"; }
    }

    binds {
      // Most actions that you can bind here can also be invoked programmatically with `niri msg action do-something`.
      Mod+Shift+Slash { show-hotkey-overlay; } // Usually the same as Mod-?, shows a list of important hotkeys.

      // Applications
      Mod+Q hotkey-overlay-title="Open Terminal" { spawn "xdg-terminal-exec"; }
      Mod+E hotkey-overlay-title="Open File Manager" { spawn "xdg-terminal-exec" "yazi"; }
      Mod+Shift+C hotkey-overlay-title="Open Color Picker" { spawn "colorpicker"; }

      Mod+X hotkey-overlay-title="Open Power Menu" { spawn ${noctalia_prefix} "sessionMenu" "toggle"; }
      Mod+S hotkey-overlay-title="Open Control Center" { spawn ${noctalia_prefix} "controlCenter" "toggle"; }
      Mod+V hotkey-overlay-title="Open Clipboard Manager" { spawn ${noctalia_prefix} "launcher" "clipboard"; }
      Mod+Space hotkey-overlay-title="Open Menu" { spawn ${noctalia_prefix} "launcher" "toggle"; }
      XF86Search hotkey-overlay-title="Open Menu" { spawn ${noctalia_prefix} "launcher" "toggle"; }

      // Window management
      F12 repeat=false { toggle-overview; }
      Mod+W repeat=false { close-window; }
      Mod+F { maximize-column; }
      Mod+Shift+F hotkey-overlay-title="Fullscreen Column" { fullscreen-window; }
      Mod+Alt+F hotkey-overlay-title="Toggle Floating" { toggle-window-floating; }
      // NOTE: niri lacks sticky/pinned feature
      // https://niri-wm.github.io/niri/FAQ.html#can-i-make-a-window-sticky-pinned-always-on-top-appear-on-all-workspaces
      // Mod+G { toggle-pin-window; }

      // Focus Movement
      Mod+H      { focus-column-or-monitor-left; }
      Mod+J      { focus-window-or-workspace-down; }
      Mod+K      { focus-window-or-workspace-up; }
      Mod+L      { focus-column-or-monitor-right; }
      Mod+Ctrl+H { focus-monitor-left; }
      Mod+Ctrl+J { focus-monitor-down; }
      Mod+Ctrl+K { focus-monitor-up; }
      Mod+Ctrl+L { focus-monitor-right; }

      Mod+Home { focus-column-first; }
      Mod+End  { focus-column-last; }

      Mod+N { focus-workspace-down; }
      Mod+P { focus-workspace-up; }

      // Mod+Tab { focus-workspace-previous; } // Switches focus between the current and the previous workspace.

      Mod+C hotkey-overlay-title="Center Column" { center-visible-columns; }

      // Toggle tabbed column display mode, "open the drawer".
      // Windows in this column will appear as vertical tabs, rather than stacked on top of each other.
      Mod+D hotkey-overlay-title="Toggle Drawer View" { toggle-column-tabbed-display; }

      Mod+T { switch-focus-between-floating-and-tiling; }

      // Move Windows
      Mod+Shift+H    { move-column-left-or-to-monitor-left; }
      Mod+Shift+J    { move-window-down-or-to-workspace-down; }
      Mod+Shift+K    { move-window-up-or-to-workspace-up; }
      Mod+Shift+L    { move-column-right-or-to-monitor-right; }
      Mod+Shift+Home { move-column-to-first; }
      Mod+Shift+End  { move-column-to-last; }
  ''
  + lib.concatLines (
    lib.imap0 (
      i: ws:
      let
        idx = toString i;
      in
      ''
        Mod+${idx} { focus-workspace "${ws}"; }
        Mod+Shift+${idx} { move-window-to-workspace "${ws}"; }
        Mod+Ctrl+${idx} { move-column-to-workspace "${ws}"; }
      ''
    ) const.workspaces
  )
  + ''
      Mod+Shift+N { move-column-to-workspace-down; }
      Mod+Shift+P { move-column-to-workspace-up; }

      Mod+Alt+Shift+N hotkey-overlay-title="Move Workspace Down" { move-workspace-down; }
      Mod+Alt+Shift+P hotkey-overlay-title="Move Workspace Up"   { move-workspace-up; }

      // Move window in and out of a column.
      // If the window is alone, they will consume it into the nearby column to the side.
      // If the window is already in a column, they will expel it out.
      Mod+BracketLeft  { consume-or-expel-window-left; }
      Mod+BracketRight { consume-or-expel-window-right; }

      Mod+Comma  hotkey-overlay-title="Consume Right Window into Column" { consume-window-into-column; }
      Mod+Period hotkey-overlay-title="Expel Right Window out of Column" { expel-window-from-column; }

      Mod+WheelScrollDown cooldown-ms=120 { focus-workspace-down; }
      Mod+WheelScrollUp   cooldown-ms=120 { focus-workspace-up; }
      Mod+Shift+WheelScrollDown           { focus-column-right; }
      Mod+Shift+WheelScrollUp             { focus-column-left; }

      // Use spawn-sh to run a shell command. Do this if you need pipes, multiple commands, etc.
      Print { spawn "nirishot"; }
      Ctrl+Print { screenshot-screen; }
      Alt+Print { screenshot-window; }

      // Window Resize
      Mod+R            { switch-preset-column-width; }
      Mod+Ctrl+R       { switch-preset-column-width-back; } // Cycling through the presets in reverse order
      Mod+Shift+R      { switch-preset-window-height; }
      Mod+Ctrl+Shift+R { reset-window-height; }

      // Makes the column "fill the rest of the space".
      Mod+Ctrl+F hotkey-overlay-title="Expand Column to width" { expand-column-to-available-width; }

      // Finer width adjustments.
      Mod+Minus hotkey-overlay-title="Fine-tune add width" { set-column-width "-10%"; }
      Mod+Equal hotkey-overlay-title="Fine-tune minus width" { set-column-width "+10%"; }
      // Finer height adjustments when in column with other windows.
      Mod+Shift+Minus { set-window-height "-10%"; }
      Mod+Shift+Equal { set-window-height "+10%"; }

      // Media Keys (Locked & Repeating)
      // Example volume keys mappings for PipeWire & WirePlumber.
      XF86AudioRaiseVolume allow-when-locked=true { spawn ${noctalia_prefix} "volume" "increase"; }
      XF86AudioLowerVolume allow-when-locked=true { spawn ${noctalia_prefix} "volume" "decrease"; }
      XF86AudioMute allow-when-locked=true        { spawn ${noctalia_prefix} "volume" "muteOutput"; }
      XF86AudioMicMute allow-when-locked=true     { spawn ${noctalia_prefix} "volume" "muteInput"; }

      // Example brightness key mappings for brightnessctl.
      XF86MonBrightnessUp allow-when-locked=true   { spawn ${noctalia_prefix} "brightness" "increase"; }
      XF86MonBrightnessDown allow-when-locked=true { spawn ${noctalia_prefix} "brightness" "decrease"; }

      // Keyboard Backlight
      XF86KbdBrightnessUp allow-when-locked=true   { spawn "brightnessctl" "--device=kbd_backlight" "set" "10%+"; }
      XF86KbdBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--device=kbd_backlight" "set" "10%-"; }

      // Audio Play
      XF86AudioPlay allow-when-locked=true { spawn ${noctalia_prefix} "media" "playPause"; }
      XF86AudioStop allow-when-locked=true { spawn ${noctalia_prefix} "media" "pause"; }
      XF86AudioPrev allow-when-locked=true { spawn ${noctalia_prefix} "media" "previous"; }
      XF86AudioNext allow-when-locked=true { spawn ${noctalia_prefix} "media" "next"; }

      // System Controls
      Mod+Z hotkey-overlay-title="Lock" { spawn "loginctl" "lock-session"; } // Locker
      Mod+Ctrl+P allow-when-locked=true hotkey-overlay-title="Power-off Monitors" {
        spawn "niri" "msg" "action" "power-off-monitors"
      }
      Ctrl+Alt+Delete { quit; } // The quit action will show a confirmation dialog to avoid accidental exits.


      // Applications such as remote-desktop clients and software KVM switches may request that niri stops processing
      // the keyboard shortcuts defined here so they may, for example, forward the key presses as-is to a remote
      // machine. It's a good idea to bind an escape hatch to toggle the inhibitor, so a buggy application can't hold
      // your session hostage.
      //
      // The allow-inhibiting=false property can be applied to other binds as well, which ensures niri always processes
      // them, even when an inhibitor is active.
      Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
    }
    // ==================================================================================
  '';
}

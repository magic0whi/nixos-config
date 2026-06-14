_: {
  xdg.configFile = ''
    binds {
        // Most actions that you can bind here can also be invoked programmatically with `niri msg action do-something`.
        Mod+Shift+Slash { show-hotkey-overlay; } // Usually the same as Mod-?, shows a list of important hotkeys.

        // Applications
        Mod+Q hotkey-overlay-title="Open Terminal" { spawn "xdg-terminal-exec"; }
        Mod+E hotkey-overlay-title="Open File Manager" { spawn "xdg-terminal-exec" "yazi"; }
        // TODO Missing color picker
        Mod+X hotkey-overlay-title="Open Power Menu" { spawn "noctalia-shell" "ipc" "--any-display" "call" "sessionMenu" "toggle"; }
        Mod+S hotkey-overlay-title="Open Control Center" { spawn "noctalia-shell" "ipc" "--any-display" "call" "controlCenter" "toggle"; }
        Mod+V hotkey-overlay-title="Open Clipboard Manager" { spawn "noctalia-shell" "ipc" "--any-display" "call" "launcher" "clipboard"; }
        Mod+Space hotkey-overlay-title="Open Menu" { spawn "noctalia-shell" "ipc" "--any-display" "call" "launcher" "toggle"; }
        XF86Search hotkey-overlay-title="Open Menu" { spawn "noctalia-shell" "ipc" "--any-display" "call" "launcher" "toggle"; }

        // Window management
        F12 repeat=false { toggle-overview; }
        Mod+W repeat=false { close-window; }
        Mod+F { maximize-column; }
        Mod+Shift+F hotkey-overlay-title="Fullscreen Column" { fullscreen-window; }
        Mod+Alt+F hotkey-overlay-title="Toggle Floating" { toggle-window-floating; }
        // NOTE: niri lacks sticky/pinned feature
        // https://niri-wm.github.io/niri/FAQ.html#can-i-make-a-window-sticky-pinned-always-on-top-appear-on-all-workspaces

        // Focus Movement
        // Mod+H { focus-column-left; }
        // Mod+J { focus-window-down; }
        // Mod+K { focus-window-up; }
        // Mod+L { focus-column-right; }
        Mod+H { focus-column-or-monitor-left; }
        Mod+J { focus-window-or-workspace-down; }
        Mod+K { focus-window-or-workspace-up; }
        Mod+L { focus-column-or-monitor-right; }
        Mod+Home { focus-column-first; }
        Mod+End { focus-column-last; }
        // TODO: lacks next
        // TODO: lacks prev

        Mod+N { focus-workspace-down; }
        Mod+P { focus-workspace-up; }

        // Mod+Tab { focus-workspace-previous; } // Switches focus between the current and the previous workspace.

        Mod+C hotkey-overlay-title="Fullscreen Column" { center-visible-columns; } // Center all fully visible columns on screen.

        // Toggle tabbed column display mode, "open the drawer".
        // Windows in this column will appear as vertical tabs, rather than stacked on top of each other.
        Mod+D hotkey-overlay-title="Toggle Drawer View" { toggle-column-tabbed-display; }

        Mod+T { focus-floating; }

        Mod+Ctrl+H { focus-monitor-left; }
        Mod+Ctrl+J { focus-monitor-down; }
        Mod+Ctrl+K { focus-monitor-up; }
        Mod+Ctrl+L { focus-monitor-right; }


        // Move Windows
        // Mod+Shift+H { move-column-left; }
        // Mod+Shift+J { move-window-down; }
        // Mod+Shift+K { move-window-up; }
        // Mod+Shift+L { move-column-right; }
        Mod+Shift+H { move-column-left-or-to-monitor-left; }
        Mod+Shift+J { move-window-down-or-to-workspace-down; }
        Mod+Shift+K { move-window-up-or-to-workspace-up; }
        Mod+Shift+L { move-column-right-or-to-monitor-right; }
        Mod+Shift+Home { move-column-to-first; }
        Mod+Shift+End  { move-column-to-last; }

        Mod+Shift+1 { move-window-to-workspace 1; }
        Mod+Shift+2 { move-window-to-workspace 2; }
        Mod+Shift+3 { move-window-to-workspace 3; }
        Mod+Shift+4 { move-window-to-workspace 4; }
        Mod+Shift+5 { move-window-to-workspace 5; }
        Mod+Shift+6 { move-window-to-workspace 6; }
        Mod+Shift+7 { move-window-to-workspace 7; }
        Mod+Shift+8 { move-window-to-workspace 8; }
        Mod+Shift+9 { move-window-to-workspace 9; }
        Mod+Shift+0 { move-window-to-workspace 0; }

        Mod+Shift+N { move-column-to-workspace-down; }
        Mod+Shift+P { move-column-to-workspace-up; }

        Mod+Alt+Shift+N hotkey-overlay-title="Move Workspace Down" { move-workspace-down; }
        Mod+Alt+Shift+P hotkey-overlay-title="Move Workspace Up" { move-workspace-up; }

        // Move window in and out of a column.
        // If the window is alone, they will consume it into the nearby column to the side.
        // If the window is already in a column, they will expel it out.
        Mod+BracketLeft  { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }

        Mod+Comma  hotkey-overlay-title="Consume Right Window into Column" { consume-window-into-column; }
        Mod+Period hotkey-overlay-title="Expel Right Window out of Column" { expel-window-from-column; }

        // TODO lacks workspace mouse scrolling

        // Screenshot Annotation via satty
        // Use spawn-sh to run a shell command. Do this if you need pipes, multiple commands, etc.
        Print { spawn-sh "set -e; grim -t ppm -g \"$(slurp -o -d -F monospace)\" - | satty --filename - --copy-command=wl-copy --annotation-size-factor 2.0 --output-filename=\"$(xdg-user-dir PICTURES)/Screenshots/Screenshot from %Y-%m-%d %H:%M:%S.png\" --actions-on-enter=\"save-to-clipboard,exit\" --brush-smooth-history-size=5 --disable-notifications"; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }

        // Window Resizing
        Mod+R { switch-preset-column-width; }
        Mod+Ctrl+R { switch-preset-column-width-back; } // Cycling through the presets in reverse order is also possible.
        Mod+Shift+R { switch-preset-window-height; }
        Mod+Ctrl+Shift+R { reset-window-height; }

        Mod+Ctrl+F hotkey-overlay-title="Expand Columnt to width" { expand-column-to-available-width; } // Makes the column "fill the rest of the space".

        // Finer width adjustments.
        Mod+Minus hotkey-overlay-title="Fine-tune add width" { set-column-width "-10%"; }
        Mod+Equal hotkey-overlay-title="Fine-tune minus width" { set-column-width "+10%"; }
        // Finer height adjustments when in column with other windows.
        Mod+Shift+Minus { set-window-height "-10%"; }
        Mod+Shift+Equal { set-window-height "+10%"; }

        // Media Keys (Locked & Repeating)
        // Example volume keys mappings for PipeWire & WirePlumber.
        // XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.01+" "--limit" "1.0"; }
        // XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.01-"; }
        // XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        // XF86AudioMicMute     allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
        XF86AudioRaiseVolume allow-when-locked=true { spawn "noctalia-shell" "ipc" "--any-display" "call" "volume" "increase"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "noctalia-shell" "ipc" "--any-display" "call" "volume" "decrease"; }
        XF86AudioMute allow-when-locked=true { spawn "noctalia-shell" "ipc" "--any-display" "call" "volume" "muteOutput"; }
        XF86AudioMicMute allow-when-locked=true { spawn "noctalia-shell" "ipc" "--any-display" "call" "volume" "muteInput"; }

        // Example brightness key mappings for brightnessctl.
        // XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "1%+"; }
        // XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "1%-"; }
        XF86MonBrightnessUp allow-when-locked=true { spawn "noctalia-shell" "ipc" "--any-display" "call" "brightness" "increase"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "noctalia-shell" "ipc" "--any-display" "call" "brightness" "decrease"; }

        // Keyboard Backlight
        XF86KbdBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--device=kbd_backlight" "set" "10%+"; }
        XF86KbdBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--device=kbd_backlight" "set" "10%-"; }

        // Audio Play
        // XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
        // XF86AudioStop allow-when-locked=true { spawn "playerctl" "stop"; }
        // XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }
        // XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
        XF86AudioPlay allow-when-locked=true { spawn "noctalia-shell" "ipc" "--any-display" "call" "media" "playPause"; }
        XF86AudioStop allow-when-locked=true { spawn "noctalia-shell" "ipc" "--any-display" "call" "media" "pause"; }
        XF86AudioPrev allow-when-locked=true { spawn "noctalia-shell" "ipc" "--any-display" "call" "media" "previous"; }
        XF86AudioNext allow-when-locked=true { spawn "noctalia-shell" "ipc" "--any-display" "call" "media" "next"; }

        // System Controls
        Mod+Z hotkey-overlay-title="Lock" { spawn "noctalia-shell" "ipc" "--any-display" "call" "lockScreen" "lock"; } // Locker
        Mod+Ctrl+P allow-when-locked=true hotkey-overlay-title="Power-off Monitors" { power-off-monitors; }
        Ctrl+Alt+Delete { quit; } // The quit action will show a confirmation dialog to avoid accidental exits.

        Mod+1 { focus-workspace "1terminal"; }
        Mod+2 { focus-workspace "2browser"; }
        Mod+3 { focus-workspace "3chat"; }
        Mod+4 { focus-workspace "4gaming"; }
        Mod+5 { focus-workspace "5music"; }
        Mod+6 { focus-workspace "6file"; }
        Mod+7 { focus-workspace "7"; }
        Mod+8 { focus-workspace "8"; }
        Mod+9 { focus-workspace "9"; }
        Mod+0 { focus-workspace "0other"; }
        Mod+Ctrl+1 { move-column-to-workspace "1terminal"; }
        Mod+Ctrl+2 { move-column-to-workspace "2browser"; }
        Mod+Ctrl+3 { move-column-to-workspace "3chat"; }
        Mod+Ctrl+4 { move-column-to-workspace "4gaming"; }
        Mod+Ctrl+5 { move-column-to-workspace "5music"; }
        Mod+Ctrl+6 { move-column-to-workspace "6file"; }
        Mod+Ctrl+7 { move-column-to-workspace "7"; }
        Mod+Ctrl+8 { move-column-to-workspace "8"; }
        Mod+Ctrl+9 { move-column-to-workspace "9"; }
        Mod+Ctrl+0 { move-column-to-workspace "0other"; }

        // Applications such as remote-desktop clients and software KVM switches may
        // request that niri stops processing the keyboard shortcuts defined here
        // so they may, for example, forward the key presses as-is to a remote machine.
        // It's a good idea to bind an escape hatch to toggle the inhibitor,
        // so a buggy application can't hold your session hostage.
        //
        // The allow-inhibiting=false property can be applied to other binds as well,
        // which ensures niri always processes them, even when an inhibitor is active.
        Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
    }
  '';
}

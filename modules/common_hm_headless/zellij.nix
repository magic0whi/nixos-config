{
  home.shellAliases."zj" = "zellij";
  programs.zellij = {
    enable = true;
    extraConfig = ''
      plugins {
        compact-bar { path "compact-bar"; }
        status-bar { path "status-bar"; }
        strider { path "strider"; }
        tab-bar { path "tab-bar"; }
      }
      keybinds clear-defaults=true {
        shared_except "locked" {
          bind "Ctrl g" { SwitchToMode "Locked"; }
          bind "Alt q" { Quit; }
          bind "Alt n" { NewPane; }
          bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
          bind "Alt j" "Alt Down" { MoveFocus "Down"; }
          bind "Alt k" "Alt Up" { MoveFocus "Up"; }
          bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
          bind "Alt =" "Alt +" { Resize "Increase"; }
          bind "Alt -" "Alt _" { Resize "Decrease"; }
          bind "Alt [" { PreviousSwapLayout; }
          bind "Alt ]" { NextSwapLayout; }
        }
        shared_except "locked" "normal"  { bind "Enter" "Esc" { SwitchToMode "Normal"; }; }

        shared_except "locked" "pane"    { bind "Ctrl p" { SwitchToMode "Pane"; }; }
        shared_except "locked" "resize"  { bind "Ctrl n" { SwitchToMode "Resize"; }; }
        shared_except "locked" "scroll"  { bind "Ctrl s" { SwitchToMode "Scroll"; }; }
        shared_except "locked" "session" { bind "Ctrl o" { SwitchToMode "Session"; }; }
        shared_except "locked" "tab"     { bind "Ctrl t" { SwitchToMode "Tab"; }; }
        shared_except "locked" "move"    { bind "Ctrl h" { SwitchToMode "Move"; }; }

        // if copy_on_select=false, uncomment this
        // normal { bind "Alt c" { Copy; }; }

        locked { bind "Ctrl g" { SwitchToMode "Normal"; }; }

        move {
          bind "Ctrl h" { SwitchToMode "Normal"; }
          bind "n" "Tab" { MovePane; }
          bind "p" { MovePaneBackwards; }
          bind "h" "Left" { MovePane "Left"; }
          bind "j" "Down" { MovePane "Down"; }
          bind "k" "Up" { MovePane "Up"; }
          bind "l" "Right" { MovePane "Right"; }
        }

        pane {
          bind "Ctrl p" { SwitchToMode "Normal"; }
          bind "h" "Left" { MoveFocus "Left"; }
          bind "j" "Down" { MoveFocus "Down"; }
          bind "k" "Up" { MoveFocus "Up"; }
          bind "l" "Right" { MoveFocus "Right"; }
          bind "p" { SwitchFocus; }
          bind "n" { NewPane; SwitchToMode "Normal"; }
          bind "d" { NewPane "Down"; SwitchToMode "Normal"; }
          bind "r" { NewPane "Right"; SwitchToMode "Normal"; }
          bind "x" { CloseFocus; SwitchToMode "Normal"; }
          bind "f" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
          bind "z" { TogglePaneFrames; SwitchToMode "Normal"; }
          bind "w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
          bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }
          bind "c" { SwitchToMode "RenamePane"; PaneNameInput 0; }
        }
        renamepane {
          bind "Ctrl c" { SwitchToMode "Normal"; }
          bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
        }

        resize {
          bind "Ctrl n" { SwitchToMode "Normal"; }
          bind "h" "Left" { Resize "Increase Left"; }
          bind "j" "Down" { Resize "Increase Down"; }
          bind "k" "Up" { Resize "Increase Up"; }
          bind "l" "Right" { Resize "Increase Right"; }
          bind "H" { Resize "Decrease Left"; }
          bind "J" { Resize "Decrease Down"; }
          bind "K" { Resize "Decrease Up"; }
          bind "L" { Resize "Decrease Right"; }
          bind "=" "+" { Resize "Increase"; }
          bind "-" "_" { Resize "Decrease"; }
        }

        scroll {
          bind "Ctrl s" { SwitchToMode "Normal"; }
          bind "e" { EditScrollback; SwitchToMode "Normal"; }
          bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
          bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
          bind "j" "Down" { ScrollDown; }
          bind "k" "Up" { ScrollUp; }
          bind "Ctrl f" "PageDown" "l" "Right" { PageScrollDown; }
          bind "Ctrl b" "PageUp" "h" "Left" { PageScrollUp; }
          bind "d" "Ctrl d" { HalfPageScrollDown; }
          bind "u" "Ctrl u" { HalfPageScrollUp; }
          // if using copy_on_select=false, uncomment this
          bind "Alt c" { Copy; }
        }

        search {
          bind "Ctrl s" { SwitchToMode "Normal"; }
          bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
          bind "j" "Down" { ScrollDown; }
          bind "k" "Up" { ScrollUp; }
          bind "Ctrl f" "PageDown" "l" "Right" { PageScrollDown; }
          bind "Ctrl b" "PageUp" "h" "Left" { PageScrollUp; }
          bind "d" "Ctrl d" { HalfPageScrollDown; }
          bind "u" "Ctrl u" { HalfPageScrollUp; }
          bind "n" { Search "Down"; }
          bind "N" { Search "Up"; }
          bind "c" { SearchToggleOption "CaseSensitivity"; }
          bind "w" { SearchToggleOption "Wrap"; }
          bind "o" { SearchToggleOption "WholeWord"; }
        }
        entersearch {
          bind "Ctrl c" "Esc" { SwitchToMode "Scroll"; };
          bind "Enter" { SwitchToMode "Search"; };
        }

        tab {
          bind "Ctrl t" { SwitchToMode "Normal"; }
          bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
          bind "h" "Left" "k" "Up" { GoToPreviousTab; }
          bind "l" "Right" "j" "Down" { GoToNextTab; }
          bind "n" { NewTab; SwitchToMode "Normal"; }
          bind "x" { CloseTab; SwitchToMode "Normal"; }
          bind "s" { ToggleActiveSyncTab; SwitchToMode "Normal"; }
          bind "1" { GoToTab 1; SwitchToMode "Normal"; }
          bind "2" { GoToTab 2; SwitchToMode "Normal"; }
          bind "3" { GoToTab 3; SwitchToMode "Normal"; }
          bind "4" { GoToTab 4; SwitchToMode "Normal"; }
          bind "5" { GoToTab 5; SwitchToMode "Normal"; }
          bind "6" { GoToTab 6; SwitchToMode "Normal"; }
          bind "7" { GoToTab 7; SwitchToMode "Normal"; }
          bind "8" { GoToTab 8; SwitchToMode "Normal"; }
          bind "9" { GoToTab 9; SwitchToMode "Normal"; }
          bind "Tab" { ToggleTab; }
        }
        renametab {
          bind "Ctrl c" { SwitchToMode "Normal"; }
          bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
        }

        session {
          bind "Ctrl o" { SwitchToMode "Normal"; }
          bind "Ctrl s" { SwitchToMode "Scroll"; }
          bind "d" { Detach; }
          bind "w" {
            LaunchOrFocusPlugin "session-manager" { floating true; move_to_focused_tab true; }
            SwitchToMode "Normal"
          }
        }
      }
    '';
  };
}

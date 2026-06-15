_: {
  # TODO: use plain kdl
  programs.zellij = {
    enable = true;
    settings = {
      plugins = {
        tab-bar.path = "tab-bar";
        status-bar.path = "status-bar";
        strider.path = "strider";
        compact-bar.path = "compact-bar";
      };
      keybinds = {
        _props.clear-defaults = true;
        _children = [
          {
            shared_except = {
              _args = [ "locked" ];
              _children = [
                {
                  bind = {
                    _args = [ "Ctrl g" ];
                    SwitchToMode = "Locked";
                  };
                }
                {
                  bind = {
                    _args = [ "Ctrl q" ];
                    Quit = { };
                  };
                }
                {
                  bind = {
                    _args = [ "Alt n" ];
                    NewPane = { };
                  };
                }
                {
                  bind = {
                    _args = [
                      "Alt h"
                      "Alt Left"
                    ];
                    MoveFocusOrTab = "Left";
                  };
                }
                {
                  bind = {
                    _args = [
                      "Alt j"
                      "Alt Down"
                    ];
                    MoveFocus = "Down";
                  };
                }
                {
                  bind = {
                    _args = [
                      "Alt k"
                      "Alt Up"
                    ];
                    MoveFocus = "Up";
                  };
                }
                {
                  bind = {
                    _args = [
                      "Alt l"
                      "Alt Right"
                    ];
                    MoveFocusOrTab = "Right";
                  };
                }
                {
                  bind = {
                    _args = [
                      "Alt ="
                      "Alt +"
                    ];
                    Resize = "Increase";
                  };
                }
                {
                  bind = {
                    _args = [
                      "Alt -"
                      "Alt _"
                    ];
                    Resize = "Decrease";
                  };
                }
                {
                  bind = {
                    _args = [ "Alt [" ];
                    PreviousSwapLayout = { };
                  };
                }
                {
                  bind = {
                    _args = [ "Alt ]" ];
                    NextSwapLayout = { };
                  };
                }
              ];
            };
          }
          {
            shared_except = {
              _args = [
                "normal"
                "locked"
              ];
              bind = {
                _args = [
                  "Enter"
                  "Esc"
                ];
                SwitchToMode = "Normal";
              };
            };
          }
          {
            shared_except = {
              _args = [
                "pane"
                "locked"
              ];
              bind = {
                _args = [ "Ctrl p" ];
                SwitchToMode = "Pane";
              };
            };
          }
          {
            shared_except = {
              _args = [
                "resize"
                "locked"
              ];
              bind = {
                _args = [ "Ctrl n" ];
                SwitchToMode = "Resize";
              };
            };
          }
          {
            shared_except = {
              _args = [
                "scroll"
                "locked"
              ];
              bind = {
                _args = [ "Ctrl s" ];
                SwitchToMode = "Scroll";
              };
            };
          }
          {
            shared_except = {
              _args = [
                "session"
                "locked"
              ];
              bind = {
                _args = [ "Ctrl o" ];
                SwitchToMode = "Session";
              };
            };
          }
          {
            shared_except = {
              _args = [
                "tab"
                "locked"
              ];
              bind = {
                _args = [ "Ctrl t" ];
                SwitchToMode = "Tab";
              };
            };
          }
          {
            shared_except = {
              _args = [
                "move"
                "locked"
              ];
              bind = {
                _args = [ "Ctrl h" ];
                SwitchToMode = "Move";
              };
            };
          }
          # {shared_except = {
          #   _args = ["tmux" "locked"];
          #   bind = {_args = ["Ctrl b"]; SwitchToMode = "Tmux";};
          # };}
        ];
        # Uncomment this and adjust key if using copy_on_select=false
        # normal.bind = {_args = ["Alt c"]; Copy = {};};
        locked.bind = {
          _args = [ "Ctrl g" ];
          SwitchToMode = "Normal";
        };
        resize._children = [
          {
            bind = {
              _args = [ "Ctrl n" ];
              SwitchToMode = "Normal";
            };
          }
          {
            bind = {
              _args = [
                "h"
                "Left"
              ];
              Resize = "Increase Left";
            };
          }
          {
            bind = {
              _args = [
                "j"
                "Down"
              ];
              Resize = "Increase Down";
            };
          }
          {
            bind = {
              _args = [
                "k"
                "Up"
              ];
              Resize = "Increase Up";
            };
          }
          {
            bind = {
              _args = [
                "l"
                "Right"
              ];
              Resize = "Increase Right";
            };
          }
          {
            bind = {
              _args = [ "H" ];
              Resize = "Decrease Left";
            };
          }
          {
            bind = {
              _args = [ "J" ];
              Resize = "Decrease Down";
            };
          }
          {
            bind = {
              _args = [ "K" ];
              Resize = "Decrease Up";
            };
          }
          {
            bind = {
              _args = [ "L" ];
              Resize = "Decrease Right";
            };
          }
          {
            bind = {
              _args = [
                "="
                "+"
              ];
              Resize = "Increase";
            };
          }
          {
            bind = {
              _args = [
                "-"
                "_"
              ];
              Resize = "Decrease";
            };
          }
        ];
        pane._children = [
          {
            bind = {
              _args = [ "Ctrl p" ];
              SwitchToMode = "Normal";
            };
          }
          {
            bind = {
              _args = [
                "h"
                "Left"
              ];
              MoveFocus = "Left";
            };
          }
          {
            bind = {
              _args = [
                "j"
                "Down"
              ];
              MoveFocus = "Down";
            };
          }
          {
            bind = {
              _args = [
                "k"
                "Up"
              ];
              MoveFocus = "Up";
            };
          }
          {
            bind = {
              _args = [
                "l"
                "Right"
              ];
              MoveFocus = "Right";
            };
          }
          {
            bind = {
              _args = [ "p" ];
              SwitchFocus = { };
            };
          }
          {
            bind = {
              _args = [ "n" ];
              _children = [
                { NewPane = { }; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "d" ];
              _children = [
                { NewPane = "Down"; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "r" ];
              _children = [
                { NewPane = "Right"; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "x" ];
              _children = [
                { CloseFocus = { }; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "f" ];
              _children = [
                { ToggleFocusFullscreen = { }; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "z" ];
              _children = [
                { TogglePaneFrames = { }; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "w" ];
              _children = [
                { ToggleFloatingPanes = { }; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "e" ];
              _children = [
                { TogglePaneEmbedOrFloating = { }; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "c" ];
              _children = [
                { SwitchToMode = "RenamePane"; }
                { PaneNameInput = 0; }
              ];
            };
          }
        ];
        move._children = [
          {
            bind = {
              _args = [ "Ctrl h" ];
              SwitchToMode = "Normal";
            };
          }
          {
            bind = {
              _args = [
                "n"
                "Tab"
              ];
              MovePane = { };
            };
          }
          {
            bind = {
              _args = [ "p" ];
              MovePaneBackwards = { };
            };
          }
          {
            bind = {
              _args = [
                "h"
                "Left"
              ];
              MovePane = "Left";
            };
          }
          {
            bind = {
              _args = [
                "j"
                "Down"
              ];
              MovePane = "Down";
            };
          }
          {
            bind = {
              _args = [
                "k"
                "Up"
              ];
              MovePane = "Up";
            };
          }
          {
            bind = {
              _args = [
                "l"
                "Right"
              ];
              MovePane = "Right";
            };
          }
        ];
        tab._children = [
          {
            bind = {
              _args = [ "Ctrl t" ];
              SwitchToMode = "Normal";
            };
          }
          {
            bind = {
              _args = [ "r" ];
              _children = [
                { SwitchToMode = "RenameTab"; }
                { TabNameInput = 0; }
              ];
            };
          }
          {
            bind = {
              _args = [
                "h"
                "Left"
                "k"
                "Up"
              ];
              GoToPreviousTab = { };
            };
          }
          {
            bind = {
              _args = [
                "l"
                "Right"
                "j"
                "Down"
              ];
              GoToNextTab = { };
            };
          }
          {
            bind = {
              _args = [ "n" ];
              _children = [
                { NewTab = { }; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "x" ];
              _children = [
                { CloseTab = { }; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "s" ];
              _children = [
                { ToggleActiveSyncTab = { }; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "1" ];
              _children = [
                { GoToTab = 1; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "2" ];
              _children = [
                { GoToTab = 2; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "3" ];
              _children = [
                { GoToTab = 3; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "4" ];
              _children = [
                { GoToTab = 4; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "5" ];
              _children = [
                { GoToTab = 5; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "6" ];
              _children = [
                { GoToTab = 6; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "7" ];
              _children = [
                { GoToTab = 7; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "8" ];
              _children = [
                { GoToTab = 8; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "9" ];
              _children = [
                { GoToTab = 9; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "Tab" ];
              ToggleTab = { };
            };
          }
        ];
        scroll._children = [
          {
            bind = {
              _args = [ "Ctrl s" ];
              SwitchToMode = "Normal";
            };
          }
          {
            bind = {
              _args = [ "e" ];
              _children = [
                { EditScrollback = { }; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [ "s" ];
              _children = [
                { SwitchToMode = "EnterSearch"; }
                { SearchInput = 0; }
              ];
            };
          }
          {
            bind = {
              _args = [ "Ctrl c" ];
              _children = [
                { ScrollToBottom = { }; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [
                "j"
                "Down"
              ];
              ScrollDown = { };
            };
          }
          {
            bind = {
              _args = [
                "k"
                "Up"
              ];
              ScrollUp = { };
            };
          }
          {
            bind = {
              _args = [
                "Ctrl f"
                "PageDown"
                "l"
                "Right"
              ];
              PageScrollDown = { };
            };
          }
          {
            bind = {
              _args = [
                "Ctrl b"
                "PageUp"
                "h"
                "Left"
              ];
              PageScrollUp = { };
            };
          }
          {
            bind = {
              _args = [
                "d"
                "Ctrl d"
              ];
              HalfPageScrollDown = { };
            };
          }
          {
            bind = {
              _args = [
                "u"
                "Ctrl u"
              ];
              HalfPageScrollUp = { };
            };
          }
          # Uncomment this and adjust key if using copy_on_select=false
          # {bind = {_args = ["Alt c"]; Copy = {};};}
        ];
        search._children = [
          {
            bind = {
              _args = [ "Ctrl s" ];
              SwitchToMode = "Normal";
            };
          }
          {
            bind = {
              _args = [ "Ctrl c" ];
              _children = [
                { ScrollToBottom = { }; }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
          {
            bind = {
              _args = [
                "j"
                "Down"
              ];
              ScrollDown = { };
            };
          }
          {
            bind = {
              _args = [
                "k"
                "Up"
              ];
              ScrollUp = { };
            };
          }
          {
            bind = {
              _args = [
                "Ctrl f"
                "PageDown"
                "l"
                "Right"
              ];
              PageScrollDown = { };
            };
          }
          {
            bind = {
              _args = [
                "Ctrl b"
                "PageUp"
                "h"
                "Left"
              ];
              PageScrollUp = { };
            };
          }
          {
            bind = {
              _args = [
                "d"
                "Ctrl d"
              ];
              HalfPageScrollDown = { };
            };
          }
          {
            bind = {
              _args = [
                "u"
                "Ctrl u"
              ];
              HalfPageScrollUp = { };
            };
          }
          {
            bind = {
              _args = [ "n" ];
              Search = "Down";
            };
          }
          {
            bind = {
              _args = [ "N" ];
              Search = "Up";
            };
          }
          {
            bind = {
              _args = [ "c" ];
              SearchToggleOption = "CaseSensitivity";
            };
          }
          {
            bind = {
              _args = [ "w" ];
              SearchToggleOption = "Wrap";
            };
          }
          {
            bind = {
              _args = [ "o" ];
              SearchToggleOption = "WholeWord";
            };
          }
        ];
        entersearch._children = [
          {
            bind = {
              _args = [
                "Ctrl c"
                "Esc"
              ];
              SwitchToMode = "Scroll";
            };
          }
          {
            bind = {
              _args = [ "Enter" ];
              SwitchToMode = "Search";
            };
          }
        ];
        renametab._children = [
          {
            bind = {
              _args = [ "Ctrl c" ];
              SwitchToMode = "Normal";
            };
          }
          {
            bind = {
              _args = [ "Esc" ];
              _children = [
                { UndoRenameTab = { }; }
                { SwitchToMode = "Tab"; }
              ];
            };
          }
        ];
        renamepane._children = [
          {
            bind = {
              _args = [ "Ctrl c" ];
              SwitchToMode = "Normal";
            };
          }
          {
            bind = {
              _args = [ "Esc" ];
              _children = [
                { UndoRenamePane = { }; }
                { SwitchToMode = "Pane"; }
              ];
            };
          }
        ];
        session._children = [
          {
            bind = {
              _args = [ "Ctrl o" ];
              SwitchToMode = "Normal";
            };
          }
          {
            bind = {
              _args = [ "Ctrl s" ];
              SwitchToMode = "Scroll";
            };
          }
          {
            bind = {
              _args = [ "d" ];
              Detach = { };
            };
          }
          {
            bind = {
              _args = [ "w" ];
              _children = [
                {
                  LaunchOrFocusPlugin = {
                    _args = [ "session-manager" ];
                    floating = true;
                    move_to_focused_tab = true;
                  };
                }
                { SwitchToMode = "Normal"; }
              ];
            };
          }
        ];
        # tmux._children = [
        #   {bind = {_args = ["["]; SwitchToMode = "Scroll";};}
        #   {bind = {
        #     _args = ["Ctrl b"];
        #     _children = [{Write = 2;}{SwitchToMode = "Normal";}];
        #   };}
        #   {bind = {
        #     _args = ["\""];
        #     _children = [{NewPane = "Down";}{SwitchToMode = "Normal";}];
        #   };}
        #   {bind = {
        #     _args = ["%"];
        #     _children = [{NewPane = "Right";}{SwitchToMode = "Normal";}];
        #   };}
        #   {bind = {
        #     _args = ["z"];
        #     _children = [{ToggleFocusFullscreen = {};}{SwitchToMode = "Normal";}];
        #   };}
        #   {bind = {
        #     _args = ["c"];
        #     _children = [{NewTab = {};}{SwitchToMode = "Normal";}];
        #   };}
        #   {bind = {_args = [","]; SwitchToMode = "RenameTab";};}
        #   {bind = {
        #     _args = ["p"];
        #     _children = [{GoToPreviousTab = {};}{SwitchToMode = "Normal";}];
        #   };}
        #   {bind = {
        #     _args = ["n"];
        #     _children = [{GoToNextTab = {};}{SwitchToMode = "Normal";}];
        #   };}
        #   {bind = {
        #     _args = ["h" "Left"];
        #     _children = [{MoveFocus = "Left";}{SwitchToMode = "Normal";}];
        #   };}
        #   {bind = {
        #     _args = ["j" "Down"];
        #     _children = [{MoveFocus = "Down";}{SwitchToMode = "Normal";}];
        #   };}
        #   {bind = {
        #     _args = ["k" "Up"];
        #     _children = [{MoveFocus = "Up";}{SwitchToMode = "Normal";}];
        #   };}
        #   {bind = {
        #     _args = ["l" "Right"];
        #     _children = [{MoveFocus = "Right";}{SwitchToMode = "Normal";}];
        #   };}
        #   {bind = {_args = ["o"]; FocusNextPane = {};};}
        #   {bind = {_args = ["d"]; Detach = {};};}
        #   {bind = {_args = ["Space"]; NextSwapLayout = {};};}
        #   {bind = {
        #     _args = ["x"];
        #     _children = [{CloseFocus = {};}{SwitchToMode = "Normal";}];
        #   };}
        # ];
      };
    };
  };
  home.shellAliases."zj" = "zellij";
}

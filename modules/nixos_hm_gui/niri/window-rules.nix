{ lib, ... }:
let
  super_rules = [
    # Terminal applications - open in workspace 1, with blur
    {
      action = ''
        open-on-workspace "1terminal"
        open-maximized true
        background-effect { blur true; }
      '';
      matches = [
        ''match app-id="Alacritty"''
        ''
          // Ghostty native blur via ext-background-effect coming in v1.4; use compositor-side blur until then
          match app-id="com.mitchellh.ghostty"
        ''
      ];
    }
    # Web browsers - open in workspace 2
    {
      action = ''
        open-on-workspace "2browser"
        open-maximized true
      '';
      matches = [
        ''match app-id="firefox"''
        ''match app-id="google-chrome"''
      ];
    }
    # Chat applications - open in workspace 3
    {
      action = ''open-on-workspace "3chat"'';
      matches = [
        ''
          // match app-id="org.telegram.desktop"
          match title="^Telegram"
        ''
        ''match app-id="wechat" ''
        ''match app-id="QQ"''
      ];
    }
    # Gaming applications - open in workspace 4
    {
      action = ''open-on-workspace "4gaming"'';
      matches = [
        ''match app-id="steam"''
        ''match app-id="steam_app_default"''
        ''match app-id="heroic"''
        ''match app-id="net.lutris.Lutris"''
        ''match app-id="com.vysp3r.ProtonPlus"''
        ''match app-id="^moe.launcher" // Run anime games on Linux''
        ''match app-id=".exe$" // All *.exe (Windows applications)''
      ];
    }
    # File management applications - open in workspace 6
    {
      action = ''open-on-workspace "6file"'';
      matches = [
        ''match app-id="com.github.johnfactotum.Foliate"''
        ''match app-id="thunar"''
      ];
    }
    # Other applications - open in workspace 0
    {
      action = ''open-on-workspace "0other"'';
      matches = [
        ''match app-id="Clash-verge"''
        ''
          match app-id="Zoom Workplace"
          match title="^(Zoom Workplace)( - Free account)?$" // Zoom Home Page
        ''
      ];
    }
    # Zoom - other windows (requires floating)
    {
      action = ''
        open-on-workspace "0other"
        open-floating true
      '';
      matches = lib.singleton ''
        match app-id="Zoom Workplace"
        exclude title="^(Zoom Workplace)( - Free account)?$"
      '';
    }
    # Notifications shows bottom right
    {
      action = ''
        open-floating true
        open-focused false
        default-floating-position x=0 y=0 relative-to="bottom-right"
      '';
      matches = lib.singleton ''match app-id="^$" // match exactly empty string, avoid to be the default behavior'';
    }
  ];
in
{
  wayland.windowManager.niri.extraConfig = ''
    // =========================== window-rules.kdl =================================
    // https://niri-wm.github.io/niri/Configuration%3A-Window-Rules.html
  ''
  + lib.concatLines (
    lib.flatten (
      map (
        rules:
        map (match: ''
          window-rule {
            ${match}
            ${rules.action}
          }
        '') rules.matches
      ) super_rules
    )
  )
  + ''
    // ==================================================================================
  '';
}

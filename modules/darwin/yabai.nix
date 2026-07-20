{
  config,
  const,
  lib,
  ...
}:
{
  services.yabai = {
    enable = true;
    config = {
      # external_bar = "off:40:0";
      layout = "bsp";
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 10;
      right_padding = 10;
      window_gap = 10;
    };
    extraConfig = ''
      # Ref: https://github.com/asmvik/yabai/issues/692
      # If no window is focused after a window closed, focus the previously focused window
      yabai -m signal --add event=window_destroyed action="yabai -m query --windows --window &> /dev/null || yabai -m window --focus recent || yabai -m window --focus last"
      yabai -m signal --add event=application_terminated action="yabai -m query --windows --window &> /dev/null || yabai -m window --focus recent || yabai -m window --focus last"
    '';
  };
  services.skhd = {
    enable = true;
    skhdConfig =
      let
        mod = "cmd";
      in
      ''
        ${mod} - q : open -na Ghostty
        # Quick terminal
        ${mod} - ` : osascript -lJavaScript ${
          config.home-manager.users.${const.username}.xdg.configHome
        }/aerospace/ghostty-actions.js 2
        ${mod} - e : open ~
        ${mod} - space : open -a Raycast

        ${mod} + shift - w : yabai -m window --close
        ${mod} + shift - f : yabai -m window --toggle zoom-fullscreen

        # Toggle Floating
        ${mod} + alt - f : yabai -m window --toggle float --grid 4:4:1:1:2:2

        ${mod} - h : yabai -m window --focus west
        ${mod} - j : yabai -m window --focus south
        ${mod} - k : yabai -m window --focus north
        ${mod} - l : yabai -m window --focus east

        # Swap Windows
        ${mod} + alt + shift - h : yabai -m window --swap west
        ${mod} + alt + shift - j : yabai -m window --swap south
        ${mod} + alt + shift - k : yabai -m window --swap north
        ${mod} + alt + shift - l : yabai -m window --swap east

        # Move Windows
        ${mod} + shift - h : yabai -m window --warp west
        ${mod} + shift - j : yabai -m window --warp south
        ${mod} + shift - k : yabai -m window --warp north
        ${mod} + shift - l : yabai -m window --warp east

        ${mod} + shift - n : yabai -m window --space next; yabai -m space --focus next
        ${mod} + shift - p : yabai -m window --space prev; yabai -m space --focus prev

        # Focus Workspace
        ${mod} - tab : yabai -m space --focus recent
        ${mod} - n : yabai -m space --focus next
        ${mod} - p : yabai -m space --focus prev

        ${lib.concatLines (
          builtins.genList (
            i:
            let
              idx = toString i;
              ws = if i == 0 then toString 10 else idx;
            in
            ''
              ${mod} - ${idx} : yabai -m space --focus ${ws}
              ${mod} + shift - ${idx} : yabai -m window --space ${ws}
            ''
          ) 10
        )}

        ## Resizing
        # Balance out layout
        ${mod} - b : yabai -m space --balance
        ${mod} + alt - h : yabai -m window --resize left:-20:0  || yabai -m window --resize right:-20:0
        ${mod} + alt - j : yabai -m window --resize bottom:0:20 || yabai -m window --resize top:0:20
        ${mod} + alt - k : yabai -m window --resize top:0:-20   || yabai -m window --resize bottom:0:-20
        ${mod} + alt - l : yabai -m window --resize right:20:0  || yabai -m window --resize left:20:0
      '';
  };
}

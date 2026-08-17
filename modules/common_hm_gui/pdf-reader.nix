{ pkgs, ... }:
{
  programs =
    if pkgs.stdenv.isDarwin then
      {
        # macOS
        sioyek = {
          enable = true;
          # Always open PDFs in a new window instead of reusing the existing instance
          config.should_launch_new_window = "1";
          bindings = {
            screen_down = "<C-d>";
            screen_up = "<C-u>";
          };
        };
      }
    else
      {
        # Linux
        zathura = {
          enable = true;
          options = {
            selection-clipboard = "clipboard";
            # catppuccin-nix enables it, lowering the PDF's readability, set it to false
            recolor = false;
          };
        };
      };
}

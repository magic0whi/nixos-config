{ pkgs, ... }:
{
  programs =
    if pkgs.stdenv.isDarwin then
      {
        sioyek = {
          # macOS
          enable = true;
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

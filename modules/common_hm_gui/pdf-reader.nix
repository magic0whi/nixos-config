{ pkgs, ... }:
{
  programs =
    if pkgs.stdenv.hostPlatform.isDarwin then
      {
        sioyek = {
          enable = true;
          # nixpkgs installs shaders/configs into Contents/MacOS, but newer sioyek looks for them in
          # Contents/Resources (missing shaders render blank pages, missing keys.config breaks keys)
          package = pkgs.sioyek.overrideAttrs {
            postInstall = ''
              cp -r pdf_viewer/shaders sioyek.app/Contents/Resources/shaders
              cp pdf_viewer/{prefs,prefs_user,keys,keys_user}.config tutorial.pdf sioyek.app/Contents/Resources/

              mkdir -p $out/Applications $out/bin
              cp -r sioyek.app $out/Applications
              ln -s $out/Applications/sioyek.app/Contents/MacOS/sioyek $out/bin/sioyek
            '';
          };
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

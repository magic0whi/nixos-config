{
  lib,
  myvars,
  pkgs,
  ...
}:
{
  programs.ghostty = {
    enable = true;
    # As of Jun 1, 2025, pkgs.ghostty is still marked as broken on MacOS (aarch64-darwin)
    # TIP: Use `pkgs.emptyFile` (or `pkgs.emptyDirectory` or `null` if formers don't work) as a dummy package
    package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    # https://ghostty.org/docs/config/reference
    settings = lib.mkMerge [
      {
        keybind = [
          "alt+left=unbind"
          "alt+right=unbind"
        ];
        font-family = myvars.monospace.name;
        font-size = 14;
        scrollback-limit = 20000;
      }
      # Options that only available on macOS
      (lib.optionalAttrs pkgs.stdenv.isDarwin {
        macos-option-as-alt = "left";
        background-opacity = 0.93;
        background-blur = true;
      })
    ];
  };
}

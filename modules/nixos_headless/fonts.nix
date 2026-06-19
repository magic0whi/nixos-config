{
  const,
  pkgs,
  ...
}:
{
  # All the fonts are linked to /nix/var/nix/profiles/system/sw/share/X11/fonts
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
    ];
    fontconfig = {
      subpixel.rgba = "rgb";
      defaultFonts = {
        serif = [
          "Noto Serif"
          "FZYaSongS-R-GB"
          "Noto Serif CJK SC"
          "Noto Serif CJK TC"
          "Noto Serif CJK JP"
        ];
        sansSerif = [
          "Inter Nerd Font"
          "Noto Sans"
          "Noto Sans CJK SC"
          "Noto Sans CJK TC"
          "Noto Sans CJK JP"
        ];
        monospace = [
          const.monospace.name
          "Noto Sans Mono"
          "Noto Sans Mono CJK SC"
          "Noto Sans Mono CJK TC"
          "Noto Sans Mono CJK JP"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}

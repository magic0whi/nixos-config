{
  myvars,
  pkgs,
  ...
}: {
  fonts.packages = with pkgs; [
    myvars.monospace.package
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    inter-nerdfont # NerdFont patch of the Inter font
    # nerdfonts
    # Ref: https://github.com/NixOS/nixpkgs/blob/nixos-unstable-small/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
    nerd-fonts.symbols-only # symbols icon only
  ];
}

{ mylib, ... }:
{
  imports = mylib.scanPath ./.;
  # Catppuccin for Nix breaks the cross compiling
  # https://github.com/catppuccin/nix/blob/de1b60ca45a578f59f7d84c8d338b346017b2161/flake.nix#L41
  catppuccin.enable = false;
}

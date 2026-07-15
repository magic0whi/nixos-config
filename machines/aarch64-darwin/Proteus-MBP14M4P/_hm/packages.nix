{ pkgs, ... }:
{
  home.packages = with pkgs; [ chezmoi ];
  programs.obsidian.enable = true;
}

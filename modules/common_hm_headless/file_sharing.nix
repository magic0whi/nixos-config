{ config, mylib, ... }:
{
  programs.rclone.enable = true;
  home.persistence."/persistent".directories = [
    "${(mylib.xdgRelTo config.home.homeDirectory config.xdg).configHome}/rclone"
  ];
}

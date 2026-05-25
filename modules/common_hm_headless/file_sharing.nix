{ lib, ... }:
{
  programs.rclone.enable = true;

  services.syncthing.enable = lib.mkDefault true;
}

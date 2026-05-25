{ pkgs, ... }:
{
  home.packages = with pkgs; [ nvtopPackages.intel ];
  services.syncthing.enable = false;
}

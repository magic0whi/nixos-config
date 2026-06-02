{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nvtopPackages.intel
    witr
  ];
  services.syncthing.enable = false;
}

{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nvtopPackages.intel
    witr # lsof, ss, systemd, etc...
  ];
}

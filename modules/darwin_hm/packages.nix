{pkgs, ...}: {
  home.packages = with pkgs; [
    iproute2mac
    utm # Virtual machine manager for Apple platforms
  ];
}

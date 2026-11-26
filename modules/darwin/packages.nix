{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    m-cli # Swiss Army Knife for macOS, https://github.com/rgcr/m-cli
    mas # Mac App Store command line interface

    stats # Beautiful system status monitor in menu bar
    betterdisplay # Unlock display settings
  ];
}

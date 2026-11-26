{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    m-cli # Swiss Army Knife for macOS, https://github.com/rgcr/m-cli
    mas # Mac App Store command line interface

    betterdisplay # Unlock display settings
  ];
}

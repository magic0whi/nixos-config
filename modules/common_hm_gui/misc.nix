{ lib, pkgs, ... }:
{
  ## BEGIN browsers.nix
  programs.firefox.enable = true;
  ## END browsers.nix
  ## BEGIN vscode.nix
  # programs.vscode = {
  #   enable = true;
  #   # Use gnome-keyring as password store
  #   package = if pkgs.stdenv.isLinux
  #   then pkgs.vscode.override {commandLineArgs = ["--password-store=gnome"];}
  #   else pkgs.vscode;
  #   # Let vscode sync and update its configuration & extensions across devices, using github account
  #   profiles.default.userSettings = {};
  # };
  # programs.joplin-desktop.enable = true; # Note taking app, https://joplinapp.org/help/
  ## END vscode.nix
}

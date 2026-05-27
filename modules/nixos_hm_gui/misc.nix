{ pkgs, ... }:
{
  ## BEGIN peripherals.nix
  services.playerctld.enable = true; # playerctl
  ## END peripherals.nix

  ## BEGIN fonts.nix
  # This allows fontconfig to discover fonts and configurations installed through home.packages, but I manage fonts at
  # system-level, not user-level
  # fonts.fontconfig.enable = true;
  ## END fonts.nix

  ## BEGIN gpg.nix
  services.gpg-agent.pinentry.package = pkgs.pinentry-qt; # GPG agent with pinentry-qt
  ## END gpg.nix

  ## BEGIN syncthing_tray.nix
  services.syncthing.tray.enable = true; # Only supports Linux platform
  ## END syncthing_tray.nix

  ## BEGIN browsers.nix
  services.psd.enable = true;
  # Enable Ozone Wayland support in Chromium and Electron based applications
  home.sessionVariables.NIXOS_OZONE_WL = "1";
  ## END browsers.nix
}

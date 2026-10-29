{ pkgs, ... }:
{
  security.soteria.enable = true; # Polkit authentication agent
  # polkitd only reads actions from the system profile (`/run/current-system/sw/share/polkit-1/actions`), so the one
  # shipped by home-manager is invisible, which breaks programs like KeePassXC's Quick Unlock ("Polkit authorisation
  # failed")
  environment.systemPackages = [ pkgs.keepassxc ]; # Offline password manager, provides both CLI and GUI
}

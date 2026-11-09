{ const, pkgs, ... }:
{
  environment.persistence."/persistent".users.${const.username}.directories = [ ".config/keepassxc" ];
  security.soteria.enable = true; # Polkit authentication agent
  # polkitd only reads actions from the system profile (`/run/current-system/sw/share/polkit-1/actions`), so the one
  # shipped by home-manager is invisible, which breaks KeePassXC's Quick Unlock ("Polkit authorisation failed").
  # Installing KeePassXC via environment.systemPackages fixes this.
  environment.systemPackages = [ pkgs.keepassxc ]; # Offline password manager, provides both CLI and GUI
}

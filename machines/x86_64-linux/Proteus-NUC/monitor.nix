{
  config,
  myvars,
  pkgs,
  ...
}:
{
  hardware.i2c.enable = true;
  users.users.${myvars.username}.extraGroups = [ config.hardware.i2c.group ];
  environment.systemPackages = with pkgs; [
    ddcutil
    ddcui
  ];
}

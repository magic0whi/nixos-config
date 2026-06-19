{
  config,
  const,
  pkgs,
  ...
}:
{
  hardware.i2c.enable = true;
  users.users.${const.username}.extraGroups = [ config.hardware.i2c.group ];
  environment.systemPackages = with pkgs; [
    ddcutil
    ddcui
  ];
  boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
}

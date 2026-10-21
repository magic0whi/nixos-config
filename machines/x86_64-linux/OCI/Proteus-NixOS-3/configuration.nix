{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName}.easytier = {
    regHost = true;
    ipv4 = "10.0.0.7/24";
    ipv6 = "fdfe:dcba:9877::7/64";
  };
  time.timeZone = "Europe/Amsterdam";
  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-36047d2c987fc4bc2acecba1b0947b321";
  # END disko-config.nix
}

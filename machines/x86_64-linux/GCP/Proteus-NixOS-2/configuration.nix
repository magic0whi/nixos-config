{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName}.easytier = {
    regHost = true;
    ipv4 = "10.0.0.6/24";
    ipv6 = "fdfe:dcba:9877::6/64";
  };
  time.timeZone = "America/New_York";
  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_proteus-nixos-2";
  # END disko-config.nix
}

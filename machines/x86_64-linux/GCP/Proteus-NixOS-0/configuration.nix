{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName}.easytier = {
    regHost = true;
    ipv4 = "10.0.0.1/24";
    ipv6 = "fdfe:dcba:9877::1/64";
  };
  time.timeZone = "America/Los_Angeles";
  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_proteus-nixos-0";
  # END disko-config.nix
}

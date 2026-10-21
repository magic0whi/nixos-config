{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName}.easytier = {
    regHost = true;
    ipv4 = "10.0.0.9/24";
    ipv6 = "fdfe:dcba:9877::9/64";
  };
  time.timeZone = "Asia/Hong_Kong";
  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_proteus-nixos-5";
  # END disko-config.nix
}

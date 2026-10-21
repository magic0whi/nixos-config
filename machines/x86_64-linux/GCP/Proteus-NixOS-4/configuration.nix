{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName}.easytier = {
    regHost = true;
    ipv4 = "10.0.0.8/24";
    ipv6 = "fdfe:dcba:9877::8/64";
  };
  time.timeZone = "Europe/London";
  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_proteus-nixos-4";
  # END disko-config.nix
}

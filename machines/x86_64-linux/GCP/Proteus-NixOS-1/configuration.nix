{ config, lib, ... }:
let
  hostname = config.networking.hostName;
in
{
  vars.hostAddrs.${hostname}.easytier = {
    regHost = true;
    ipv4 = "10.0.0.5/24";
    ipv6 = "fdfe:dcba:9877::5/64";
  };
  time.timeZone = "America/Los_Angeles";
  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_${lib.toLower hostname}";
  # END disko-config.nix
}

{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      regHost = true;
    in
    {
      tailscale = {
        inherit regHost;
        ipv4 = "100.121.95.98";
        ipv6 = "fd7a:115c:a1e0::df3a:5f62";
      };
      easytier = {
        inherit regHost;
        ipv4 = "10.0.0.5";
        ipv6 = "fdfe:dcba:9877::5";
      };
    };
  time.timeZone = "America/Los_Angeles";
  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_proteus-nixos-1";
  # END disko-config.nix
}

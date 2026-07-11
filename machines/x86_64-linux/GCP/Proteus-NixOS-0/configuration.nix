{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      regHost = true;
    in
    {
      tailscale = {
        inherit regHost;
        ipv4 = "100.68.75.16";
        ipv6 = "fd7a:115c:a1e0::a13a:4b11";
      };
      easytier = {
        inherit regHost;
        ipv4 = "10.0.0.1";
        ipv6 = "fdfe:dcba:9877::1";
      };
    };
  time.timeZone = "America/Los_Angeles";
  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_proteus-nixos-0";
  # END disko-config.nix
}

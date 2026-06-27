{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      regHost = true;
    in
    {
      tailscale = {
        inherit regHost;
        ipv4 = "100.113.250.94";
        ipv6 = "fd7a:115c:a1e0::703a:fa5e";
      };
      easytier = {
        inherit regHost;
        ipv4 = "10.0.0.7";
        ipv6 = "fdfe:dcba:9877::7";
      };
    };
  time.timeZone = "Europe/London";
  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_proteus-nixos-3";
  # END disko-config.nix
}

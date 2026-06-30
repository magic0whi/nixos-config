{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      regHost = true;
    in
    {
      tailscale = {
        inherit regHost;
        ipv4 = "100.124.97.2";
        ipv6 = "fd7a:115c:a1e0::273a:6103";
      };
      easytier = {
        inherit regHost;
        ipv4 = "10.0.0.8";
        ipv6 = "fdfe:dcba:9877::8";
      };
    };
  time.timeZone = "Europe/London";
  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_proteus-nixos-4";
  # END disko-config.nix
}

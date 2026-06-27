{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      regHost = true;
    in
    {
      tailscale = {
        inherit regHost;
        ipv4 = "100.90.238.8";
        ipv6 = "fd7a:115c:a1e0::c53a:ee08";
      };
      easytier = {
        inherit regHost;
        ipv4 = "10.0.0.9";
        ipv6 = "fdfe:dcba:9877::9";
      };
    };
  time.timeZone = "Asia/Hong_Kong";
  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_proteus-nixos-5";
  # END disko-config.nix
}

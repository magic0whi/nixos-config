{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      regHost = true;
    in
    {
      tailscale = {
        inherit regHost;
        ipv4 = "100.78.150.50";
        ipv6 = "fd7a:115c:a1e0::823a:9632";
      };
      easytier = {
        inherit regHost;
        ipv4 = "10.0.0.6";
        ipv6 = "fdfe:dcba:9877::6";
      };
    };
  time.timeZone = "Europe/Berlin";
  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_proteus-nixos-2";
  # END disko-config.nix
}

{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      regHost = true;
    in
    {
      tailscale = {
        inherit regHost;
        ipv4 = "100.94.6.28";
        ipv6 = "fd7a:115c:a1e0::3b31:61d";
      };
      easytier = {
        inherit regHost;
        ipv4 = "10.0.0.7";
        ipv6 = "fdfe:dcba:9877::7";
      };
    };
  time.timeZone = "Europe/Amsterdam";
  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-36047d2c987fc4bc2acecba1b0947b321";
  # END disko-config.nix
}

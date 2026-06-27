{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      regHost = true;
    in
    {
      tailscale = {
        inherit regHost;
        ipv4 = "100.95.17.39/10";
        ipv6 = "fd7a:115c:a1e0::783a:1127/48";
      };
      easytier = {
        inherit regHost;
        ipv4 = "10.0.0.4/24";
        ipv6 = "fdfe:dcba:9877::4/64";
      };
    };
  # launchd.daemons.tailscaled.serviceConfig = {
  #   StandardErrorPath = "/Library/Logs/com.tailscale.ipn.stderr.log";
  #   StandardOutPath = "/Library/Logs/com.tailscale.ipn.stdout.log";
  # };
}

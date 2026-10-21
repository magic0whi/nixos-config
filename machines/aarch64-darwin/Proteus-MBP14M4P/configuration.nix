{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName}.easytier = {
    regHost = true;
    ipv4 = "10.0.0.4/24";
    ipv6 = "fdfe:dcba:9877::4/64";
  };

  services.sing-box.generateMobileConfig.enable = true;
}

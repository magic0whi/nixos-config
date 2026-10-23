{ config, const, ... }:
{
  vars.hostAddrs.${config.networking.hostName}.easytier = {
    regHost = true;
    ipv4 = "10.0.0.4/24";
    ipv6 = "fdfe:dcba:9877::4/64";
  };

  services.sing-box.generateMobileConfig.enable = true;
  ## BEGIN easytier.nix
  services.easytier.instances.main.settings.peers = with const.networking.allHostAddrs; [
    "udp://${Proteus-NUC.wire.ipv4NoCidr}"
    "udp://${Proteus-Desktop.wire.ipv4NoCidr}"
  ];
  ## END easytier.nix
}

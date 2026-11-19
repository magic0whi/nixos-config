{ config, const, ... }:
let
  hm = config.home-manager.users.${const.username};
in
{
  networking.firewall = {
    allowedTCPPorts = hm.networking.firewall.allowedTCPPorts;
    allowedUDPPorts = hm.networking.firewall.allowedUDPPorts;
  };
}

{ const, ... }:
{
  imports = [ const.syncthing ];
  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [
      21027 # Syncthing discovery broadcasts on IPv4 and multicasts on IPv6
      22000
    ];
  };
}

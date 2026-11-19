# Implementations are in hm-firewall.nix
{ lib, ... }:
{
  options.networking.firewall = {
    allowedTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      description = "List of TCP ports on which incoming connections are accepted.";
    };
    allowedUDPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      description = "List of open UDP ports.";
    };
  };
}

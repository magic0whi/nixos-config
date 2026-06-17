{
  config,
  lib,
  pkgs,
  ...
}:
{
  networking.firewall = lib.mkMerge [
    # systemd-nspawn
    { extraInputRules = ''udp dport bootps accept comment "Allow DHCP server (systemd-nspawn)"''; }
    # Iperf 3
    {
      allowedTCPPorts = lib.mkIf (builtins.elem pkgs.iperf3 config.environment.systemPackages) [ 5201 ];
      allowedUDPPorts = lib.mkIf (builtins.elem pkgs.iperf3 config.environment.systemPackages) [ 5201 ];
    }
  ];
}

{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
{
  networking.firewall =
    let
      hm_cfg = config.home-manager.users.${myvars.username} or { };
    in
    lib.mkMerge [
      {
        # enable = false; # Disable firewall

        # `systemd.nspawn.<name>.enable` == true
        extraInputRules = ''
          # ip saddr 192.168.1.0/24 accept comment "Allow from LAN"
          ip6 saddr { fe80::/16 } accept comment "Allow from Link-Local / ULA-Prefix (IPv6)"
          udp dport bootps accept comment "Allow DHCP server (systemd-nspawn)"
        '';
      }
      # Iperf 3
      {
        allowedTCPPorts = lib.mkIf (builtins.elem pkgs.iperf3 config.environment.systemPackages) [ 5201 ];
        allowedUDPPorts = lib.mkIf (builtins.elem pkgs.iperf3 config.environment.systemPackages) [ 5201 ];
      }
      {
        allowedTCPPorts = lib.mkIf (builtins.elem pkgs.localsend (hm_cfg.home.packages or [ ])) [ 53317 ];
        allowedUDPPorts = lib.mkIf (builtins.elem pkgs.localsend (hm_cfg.home.packages or [ ])) [ 53317 ];
      }
      # Syncthing
      {
        allowedTCPPorts = lib.mkIf (hm_cfg.services.syncthing.enable or false) [ 22000 ]; # TCP Transfer
        # 21027: Syncthing discovery broadcasts on IPv4 and multicasts on IPv6
        allowedUDPPorts = lib.mkIf (hm_cfg.services.syncthing.enable or false) [
          21027
          22000
        ]; # QUIC Transfer
      }
      # EasyTier
      (lib.mkIf config.services.easytier.enable {
        allowedTCPPortRanges = [
          {
            from = 11010;
            to = 11013;
          }
        ];
        allowedUDPPortRanges = [
          {
            from = 11010;
            to = 11012;
          }
        ];
      })
    ];
  # Let Tailscale auto detect the firewall type (nftables)
  systemd.services = lib.mkIf config.services.tailscale.enable {
    tailscaled.environment.TS_DEBUG_FIREWALL_MODE = "auto";
  };
}

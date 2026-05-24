{
  config,
  lib,
  myvars,
  pkgs,
  ...
}: {
  networking.firewall = let
    hm_cfg = config.home-manager.users.${myvars.username};
    iperf3_port = 5201;
    syncthing_port = 22000; # Syncthing TCP/QUIC transfers
    localsend_port = 53317; # LocalSend (HTTP/TCP)/(Multicast/UDP)
  in {
    # enable = false; # Disable firewall
    allowedTCPPorts =
      lib.optional (builtins.elem pkgs.iperf3 config.environment.systemPackages) iperf3_port
      ++ (lib.optional hm_cfg.services.syncthing.enable syncthing_port)
      ++ (lib.optional (builtins.elem pkgs.localsend hm_cfg.home.packages) localsend_port);
    allowedUDPPorts =
      lib.optional (builtins.elem pkgs.iperf3 config.environment.systemPackages) iperf3_port
      # 21027: Syncthing discovery broadcasts on IPv4 and multicasts on IPv6
      ++ (lib.optionals hm_cfg.services.syncthing.enable [21027 syncthing_port])
      ++ (lib.optional (builtins.elem pkgs.localsend hm_cfg.home.packages) localsend_port);

    # TODO check whether libvirt dnsmasq add rules to allow, and add a optionalString to check if any
    # `systemd.nspawn.<name>.enable` == true
    extraInputRules = ''
      # ip saddr 192.168.1.0/24 accept comment "Allow from LAN"
      ip6 saddr { fe80::/16 } accept comment "Allow from Link-Local / ULA-Prefix (IPv6)"
      udp dport bootps accept comment "Allow DHCP server (systemd-nspawn)"
    '';
  };
}

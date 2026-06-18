_: {
  # To test a link file whether malformed: `sudo udevadm test-builtin net_setup_link /sys/class/net/<iface>`
  systemd.network = {
    links =
      let
        default_link_cfg = {
          NamePolicy = "keep kernel database onboard slot path";
          AlternativeNamesPolicy = "database onboard slot path mac";
          MACAddressPolicy = "persistent";
        };
      in
      {
        "10-enp46s0" = {
          # To get the ID path: `sudo udevadm info -q property -p /sys/class/net/enp46s0 | grep ID_PATH=`
          matchConfig.Path = "pci-0000:2e:00.0";
          # sudo nix run nixpkgs#ethtool -- -k enp46s0
          linkConfig = default_link_cfg // {
            GenericReceiveOffloadList = false; # rx-gro-list, conflict with rx-udp-gro-forwarding
            GenericReceiveOffloadUDPForwarding = true; # rx-udp-gro-forwarding
            NTupleFilter = true; # ntuple-filters
          };
        };
        "10-wlo1" = {
          matchConfig.Path = "pci-0000:00:14.3";
          linkConfig = default_link_cfg // {
            GenericReceiveOffloadList = false; # rx-gro-list, conflict with rx-udp-gro-forwarding
            GenericReceiveOffloadUDPForwarding = true; # rx-udp-gro-forwarding
            TCPMangleIdSegmentationOffload = true; # tx-tcp-mangleid-segmentation
          };
        };
      };
    networks."10-enp46s0-disable-ipv6" = {
      name = "enp46s0";
      DHCP = "yes";
      # networkConfig = {
      #   # Disable IPv6
      #   IPv6AcceptRA = false;
      #   LinkLocalAddressing = false;
      # };
    };
    networks."10-wlo1" = {
      name = "wlo1";
      DHCP = "yes";
      networkConfig.IgnoreCarrierLoss = "3s";
      dhcpV4Config.RouteMetric = 20;
      ipv6AcceptRAConfig.RouteMetric = 20;
      # networkConfig = {
      #   # Disable IPv6
      #   IPv6AcceptRA = false;
      #   LinkLocalAddressing = false;
      # };
    };
  };
}

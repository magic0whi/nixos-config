{
  config,
  const,
  lib,
  machineConfigs,
  ...
}:
{
  services.resolved = {
    enable = true;
    # This triggers recursive queries to the apex domain, which slows down domestic sites. It can also completely
    # break your internet access if the proxy server goes down while systemd-resolved is fetching DS records for
    # proxied apex domains like "com"
    settings.Resolve.DNSSEC = if config.services.sing-box.enable then false else "allow-downgrade";
  };

  systemd.network.networks."50-overlay-dns" =
    let
      ns_hostname = const.networking.findFirstHostBySubdomain "ns1";
    in
    lib.mkIf config.services.easytier.enable {
      name = config.services.easytier.instances.main.extraSettings.flags.dev_name;

      networkConfig.KeepConfiguration = "yes"; # Prevent systemd-networkd managing other things (like IP addresses)

      domains = [
        "${const.domain}" # Search Domain
      ]
      # Routing Domain for reverse zones
      ++ lib.remove "~${const.domain}" (
        # The '~' prefix makes this a routing domain
        lib.mapAttrsToList (_: zone: "~${zone.name}") machineConfigs.${ns_hostname}.config.services.bind.zones
      );

      dns = with const.networking.allHostAddrs.${ns_hostname}.easytier; [
        "${ipv4NoCidr}#${const.domain}"
        "${ipv6NoCidr}#${const.domain}"
      ];
    };

  # Trust Island
  environment.etc."dnssec-trust-anchors.d/${const.domain}.positive".text = ''
    ${const.domain}. IN DS 40751 15 2 EFFF70FD3922613584774DE050E31D5A3FFF988E45EB5C75296BF448B5B01FCF
  '';
  environment.etc."dnssec-trust-anchors.d/et_v4_rev_zone.positive".text = ''
    0.0.10.in-addr.arpa. IN DS 3009 15 2 E93B662038A9985D4A4BAEA2F619593EF4699EAFA08612BD7C3FCD00691FA85C
  '';
  environment.etc."dnssec-trust-anchors.d/et_v6_rev_zone.positive.positive".text = ''
    0.0.0.0.7.7.8.9.a.b.c.d.e.f.d.f.ip6.arpa. IN DS 1147 15 2 2DCEF637F1D130E0CF63F33FEF81C99E01C8B187A8AE75A3985545400FF4A763
  '';
}

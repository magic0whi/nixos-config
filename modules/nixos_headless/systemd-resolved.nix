{
  config,
  myvars,
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
  # Trust Island
  environment.etc."dnssec-trust-anchors.d/${myvars.domain}.positive".text = ''
    ${myvars.domain}. IN DS 40751 15 2 EFFF70FD3922613584774DE050E31D5A3FFF988E45EB5C75296BF448B5B01FCF
  '';
  environment.etc."dnssec-trust-anchors.d/ts_v4_rev_zone.positive".text = ''
    100.in-addr.arpa. IN DS 16452 15 2 673360156B641DBA72909952F230FA34A6FA8D8D249A8A8A55C05A94EC6794FF
  '';
  environment.etc."dnssec-trust-anchors.d/ts_v6_rev_zone.positive.positive".text = ''
    0.e.1.a.c.5.1.1.a.7.d.f.ip6.arpa. IN DS 2790 15 2 B90A8FDD8D504FC3182F57750FC433EF8D43AFA8ABE6716A3DC49BFBCCD5F3EA
  '';
  environment.etc."dnssec-trust-anchors.d/et_v4_rev_zone.positive".text = ''
    0.0.10.in-addr.arpa. IN DS 3009 15 2 E93B662038A9985D4A4BAEA2F619593EF4699EAFA08612BD7C3FCD00691FA85C
  '';
  environment.etc."dnssec-trust-anchors.d/et_v6_rev_zone.positive.positive".text = ''
    0.0.0.0.7.7.8.9.a.b.c.d.e.f.d.f.ip6.arpa. IN DS 1147 15 2 2DCEF637F1D130E0CF63F33FEF81C99E01C8B187A8AE75A3985545400FF4A763
  '';
}

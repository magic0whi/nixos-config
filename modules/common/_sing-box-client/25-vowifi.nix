{
  dnsServerCfg,
  lib,
  mylib,
  selectorCfg,
  ...
}:
let
  pri = 0.25;
  out = "VoWiFi";
  rules = [
    {
      network = "udp";
      port = [
        500
        4500
      ];
    }
    {
      network = "tcp";
      port = 143;
    }
    {
      domain_suffix = [
        "3gppnetwork.org"
        "jibecloud.net"
        "ee.co.uk"
        "hkcsl.com"
      ];
    }
  ];
in
{
  dns = {
    # NOTE: The 8.8.8.8 cannot access if use Direct outbound
    servers = lib.singleton (
      dnsServerCfg.default
      // {
        tag = out;
        detour = out;
      }
    );
    rules = lib.mkOrder (pri * 2000) (mylib.mkSbRules true out rules);
  };
  outbounds = lib.singleton (
    selectorCfg
    // {
      tag = out;
      default = "Default";
    }
  );
  route.rules = lib.mkOrder (pri * 1000) (mylib.mkSbRules false out rules);
}

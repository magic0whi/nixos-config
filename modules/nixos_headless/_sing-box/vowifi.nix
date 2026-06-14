{
  dnsServerCfg,
  lib,
  mylib,
  selectorCfg,
  ...
}:
let
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
    # TODO: The 8.8.8.8 cannot access if use Direct outbound
    servers = lib.singleton (
      dnsServerCfg.default
      // {
        tag = out;
        detour = out;
      }
    );
    rules = mylib.mkSbRules true out rules;
  };
  outbounds = lib.singleton (
    selectorCfg
    // {
      tag = out;
      default = "Default";
    }
  );
  route.rules = mylib.mkSbRules false out rules;
}

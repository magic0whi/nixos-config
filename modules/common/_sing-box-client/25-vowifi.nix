{
  const,
  dnsServerCfg,
  lib,
  mylib,
  selectorCfg,
  ...
}:
let
  pri = 0.25;
  realip_pri = pri * const.sb.dnsFakeIpPri;
  no_sniff_pri = pri * const.sb.routeSniffPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "VoWiFi";
  rules = lib.singleton {
    domain_suffix = [
      "3gppnetwork.org"
      "jibecloud.net"
      "ee.co.uk"
      "hkcsl.com"
    ];
  };
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
    rules = lib.mkOrder realip_pri (mylib.mkSbRules true out rules);
  };
  outbounds = lib.singleton (
    selectorCfg
    // {
      tag = out;
      default = "Default";
    }
  );
  route.rules =
    let
      mkSbRules = mylib.mkSbRules false;
    in
    lib.mkMerge [
      (lib.mkOrder no_sniff_pri (
        mkSbRules out [
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
        ]
      ))
      (lib.mkOrder sniff_pri (mkSbRules out rules))
    ];
}

{
  const,
  dnsServerCfg,
  lib,
  mylib,
  selectorCfg,
  ...
}:
let
  pri = 0.50;
  fakeip_pri = pri * (2000 - const.sb.dnsFakeIpPri) + const.sb.dnsFakeIpPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "Coinbase";
  rules = lib.singleton {
    domain_suffix = [
      "coinbase.com"
      "wallet.elephant-blue.org"
    ];
  };
in
{
  dns = {
    servers = lib.singleton (
      dnsServerCfg.default
      // {
        tag = out;
        detour = out;
      }
    );
    rules = lib.mkOrder fakeip_pri (mylib.mkSbRules true out rules);
  };
  outbounds = lib.singleton (
    selectorCfg
    // {
      tag = out;
      default = "Germany";
    }
  );
  route.rules = lib.mkOrder sniff_pri (mylib.mkSbRules false out rules);
}

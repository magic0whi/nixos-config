{
  const,
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  pri = 0.50;
  fakeip_pri = pri * (2000 - const.sb.dnsFakeIpPri) + const.sb.dnsFakeIpPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "Stripe";
  rules = [ { rule_set = "geosite-stripe"; } ];
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
      default = "HongKong";
    }
  );
  route = {
    rules = lib.mkOrder sniff_pri (mylib.mkSbRules false out rules);
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-stripe";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/stripe.srs";
      }
    );
  };
}

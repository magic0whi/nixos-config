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

  out = "PayPal";
  rules = [
    # Marqeta: card issuing/processing (PayPal/Venmo debit cards)
    { domain_suffix = "marqeta.com"; }
    { rule_set = "geosite-paypal"; }
    {
      domain_suffix = [
        "paypal.co.uk"
        "paypal-api.arkoselabs.com" # Arkose Labs: PayPal fraud/bot challenge
        "paypal-api.arkose.com.cn" # Arkose Labs: PayPal China fallback
      ];
    }
  ];
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
      default = "UnitedKingdom";
    }
  );
  route = {
    rules = lib.mkOrder sniff_pri (mylib.mkSbRules false out rules);
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-paypal";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/paypal.srs";
      }
    );
  };
}

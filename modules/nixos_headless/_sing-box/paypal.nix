{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "PayPal";
  rules = [
    { domain_suffix = "marqeta.com"; }
    { rule_set = "geosite-paypal"; }
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
    rules = mylib.mkSbRules true out rules;
  };
  outbounds = lib.singleton (
    selectorCfg
    // {
      tag = out;
      default = "UnitedKingdom";
    }
  );
  route = {
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-paypal";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/paypal.srs";
      }
    );
    rules = mylib.mkSbRules false out rules;
  };
}

{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
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
    rules = mylib.mkSbRules true out rules;
  };
  outbounds = lib.singleton (
    selectorCfg
    // {
      tag = out;
      default = "HongKong";
    }
  );
  route = {
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-stripe";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/stripe.srs";
      }
    );
    rules = mylib.mkSbRules false out rules;
  };
}

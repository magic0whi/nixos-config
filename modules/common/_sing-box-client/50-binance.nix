{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "Binance";
  rules = [ { rule_set = "geosite-binance"; } ];
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
      default = "Default";
    }
  );
  route = {
    rules = mylib.mkSbRules false out rules;
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-binance";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/binance.srs";
      }
    );
  };
}

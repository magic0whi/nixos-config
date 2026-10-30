{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "eBay";
  rules = [ { rule_set = "geosite-ebay"; } ];
in
{
  dns = {
    servers = lib.singleton (
      dnsServerCfg.direct
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
      default = "Direct";
    }
  );
  route = {
    rules = mylib.mkSbRules false out rules;
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-ebay";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/ebay.srs";
      }
    );
  };
}

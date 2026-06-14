{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "Speedtest";
  rules = [ { rule_set = "geosite-category-speedtest"; } ];
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
      default = "Default";
    }
  );
  route = {
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-category-speedtest";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/category-speedtest.srs";
      }
    );
    rules = mylib.mkSbRules false out rules;
  };
}

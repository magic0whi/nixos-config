{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "Pixiv";
  rules = [ { rule_set = "geosite-pixiv"; } ];
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
        tag = "geosite-pixiv";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/pixiv.srs";
      }
    );
    rules = mylib.mkSbRules false out rules;
  };
}

{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "HSBC";
  rules = [
    { domain_suffix = "checkfreeweb.com"; } # HSBC US Bank-to-Bank
    { rule_set = "geosite-hsbc"; }
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
      default = "Direct";
    }
  );
  route = {
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-hsbc";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/hsbc.srs";
      }
    );
    rules = mylib.mkSbRules false out rules;
  };
}

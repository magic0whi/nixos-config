{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "OKX";
  rules = [
    {
      domain_suffix = [
        "okcoin.com"
        "okx.ac"
        "okx.cab"
      ];
    }
    { rule_set = "geosite-okx"; }
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
      default = "Default";
    }
  );
  route = {
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-okx";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/okx.srs";
      }
    );
    rules = mylib.mkSbRules false out rules;
  };
}

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
    {
      domain_suffix = [
        "checkfreeweb.com" # HSBC US Bank-to-Bank
        "firstdata.com" # HSBC US credit card
      ];
    }

    { rule_set = "geosite-hsbc"; }
  ];
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
        tag = "geosite-hsbc";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/hsbc.srs";
      }
    );
  };
}

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
  super_rules = [
    {
      inherit out;
      rules = [
        {
          domain_suffix = [
            "checkfreeweb.com" # HSBC US Bank-to-Bank
            "firstdata.com" # HSBC US credit card
          ];
        }
        { rule_set = "geosite-hsbc"; }
      ];
    }
    {
      out = "Default";
      rules = lib.singleton { domain_suffix = [ "d3ksttzjeov72n.cloudfront.net" ]; };
    }
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
    rules = builtins.concatMap (rules: mylib.mkSbRules true rules.out rules.rules) super_rules;
  };
  outbounds = lib.singleton (
    selectorCfg
    // {
      tag = out;
      default = "Direct";
    }
  );
  route = {
    rules = builtins.concatMap (rules: mylib.mkSbRules false rules.out rules.rules) super_rules;
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-hsbc";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/hsbc.srs";
      }
    );
  };
}

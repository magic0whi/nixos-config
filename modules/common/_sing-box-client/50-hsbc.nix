{
  const,
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  pri = 0.50;
  fakeip_pri = pri * (2000 - const.sb.dnsFakeIpPri) + const.sb.dnsFakeIpPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

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
      rules = lib.singleton {
        domain_suffix = [
          "adobesign.com" # Document sign
          "d3ksttzjeov72n.cloudfront.net" # firstdata
        ];
      };
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
    rules = lib.mkOrder fakeip_pri (builtins.concatMap (rules: mylib.mkSbRules true rules.out rules.rules) super_rules);
  };
  outbounds = lib.singleton (
    selectorCfg
    // {
      tag = out;
      default = "Direct";
    }
  );
  route = {
    rules = lib.mkOrder sniff_pri (builtins.concatMap (rules: mylib.mkSbRules false rules.out rules.rules) super_rules);
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-hsbc";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/hsbc.srs";
      }
    );
  };
}

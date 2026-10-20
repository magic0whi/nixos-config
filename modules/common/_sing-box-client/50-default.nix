{
  lib,
  mylib,
  ruleSetCfg,
  ...
}:
let
  out = "Default";
  rules = [
    {
      domain_suffix = [
        "naixi.net"
        "shuzijumin.com"
        "wenziwanka.com"
      ];
    }
    { rule_set = [ "geosite-gfw" ]; }
  ];
in
{
  dns.rules = mylib.mkSbRules true out rules;
  route = {
    rules =
      let
        mkSbRules = mylib.mkSbRules false;
      in
      lib.mkMerge [
        (lib.mkBefore (mkSbRules out [ { rule_set = [ "geoip-telegram" ]; } ]))
        (mkSbRules out rules)
      ];
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geosite-gfw";
          url = "${urlPrefix}/geo/geosite/gfw.srs";
        }
        {
          tag = "geoip-telegram";
          url = "${urlPrefix}/geo/geoip/telegram.srs";
        }
      ];
  };
}

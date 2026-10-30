{
  lib,
  mylib,
  ruleSetCfg,
  ...
}:
let
  pri = 0.51;
  out = "Default";
  rules = [
    { domain_suffix = [ "shuzijumin.com" ]; }
    { rule_set = [ "geosite-gfw" ]; }
  ];
in
{
  dns.rules = lib.mkOrder (pri * 2000) (mylib.mkSbRules true out rules);
  route = {
    rules =
      let
        mkSbRules = mylib.mkSbRules false;
      in
      lib.mkMerge [
        (lib.mkBefore (mkSbRules out [ { rule_set = [ "geoip-telegram" ]; } ]))
        (lib.mkOrder (pri * 2000) (mkSbRules out rules))
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

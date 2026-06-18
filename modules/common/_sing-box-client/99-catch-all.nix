{
  lib,
  mylib,
  ruleSetCfg,
  ...
}:
let
  out = "Direct";
  non_dns_rules = [ { rule_set = [ "geoip-cn" ]; } ];
  rules = [ { rule_set = [ "geosite-cn" ]; } ];
in
{
  dns.rules = lib.mkOrder 2000 (mylib.mkSbRules true out rules);
  route = {
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geoip-cn";
          url = "${urlPrefix}/geo/geoip/cn.srs";
        }
        {
          tag = "geosite-cn";
          url = "${urlPrefix}/geo/geosite/cn.srs";
        }
      ];
    rules = lib.mkMerge (
      let
        mkSbRules = mylib.mkSbRules false;
      in
      [
        (lib.mkBefore (mkSbRules out non_dns_rules))
        (lib.mkOrder 2000 (mkSbRules out rules))
      ]
    );
  };
}

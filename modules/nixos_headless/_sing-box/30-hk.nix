{ mylib, ruleSetCfg, ... }:
let
  out = "HongKong";
  rules = [
    { domain_suffix = "carousell.com.hk"; }
    {
      rule_set = [
        "geosite-hketgroup"
        "geosite-line"
      ];
    }
  ];
in
{
  dns.rules = mylib.mkSbRules true out rules;
  route = {
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geosite-hketgroup";
          url = "${urlPrefix}/geo/geosite/hketgroup.srs";
        }
        {
          tag = "geosite-line";
          url = "${urlPrefix}/geo/geosite/line.srs";
        }
      ];
    rules = mylib.mkSbRules false out rules;
  };
}

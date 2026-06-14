{ mylib, ruleSetCfg, ... }:
let
  out = "Germany";
  rules = [
    {
      domain_suffix = [
        "bonify.de"
        "coinbase.com"
        "bybit.eu"
        "braze.eu"
      ];
    }
    {
      rule_set = [
        "geosite-bybit"
        "geosite-n26"
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
          tag = "geosite-bybit";
          url = "${urlPrefix}/geo/geosite/bybit.srs";
        }
        {
          tag = "geosite-n26";
          url = "${urlPrefix}/geo/geosite/n26.srs";
        }
      ];
    rules = mylib.mkSbRules false out rules;
  };
}

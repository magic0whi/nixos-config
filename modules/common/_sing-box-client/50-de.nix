{ mylib, ruleSetCfg, ... }:
let
  out = "Germany";
  rules = [
    {
      domain_suffix = [
        "bonify.de"
        "bybit.eu"
        "tink.com" # Easy bank transfer
        "bunq.com"
      ];
    }
    {
      rule_set = [
        "geosite-n26"
        "geosite-bybit"
      ];
    }
  ];
in
{
  dns.rules = mylib.mkSbRules true out rules;
  route = {
    rules = mylib.mkSbRules false out rules;
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
  };
}

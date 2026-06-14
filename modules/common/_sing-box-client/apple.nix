{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "Apple";
  non_dns_rules = [ { rule_set = [ "geoip-apple" ]; } ];
  rules = [ { rule_set = [ "geosite-apple" ]; } ];
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
      default = "Direct";
    }
  );
  route = {
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geoip-apple";
          url = "${urlPrefix}/geo-lite/geoip/apple.srs";
        }
        {
          tag = "geosite-apple";
          url = "${urlPrefix}/geo/geosite/apple.srs";
        }
      ];
    rules = lib.mkMerge (
      let
        mkSbRules = mylib.mkSbRules false;
      in
      [
        (lib.mkBefore (mkSbRules out non_dns_rules))
        (mkSbRules out rules)
      ]
    );
  };
}

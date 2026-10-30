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
  rules = [
    {
      inherit out;
      rules = [ { rule_set = [ "geosite-apple" ]; } ];
    }
    {
      out = "AppleUpdate";
      rules = [ { rule_set = [ "geosite-apple-update" ]; } ];
    }
  ];

in
{
  dns = {
    servers = map (
      rule:
      dnsServerCfg.direct
      // {
        tag = rule.out;
        detour = rule.out;
      }
    ) rules;
    rules =
      let
        mkSbRules = mylib.mkSbRules true;
      in
      builtins.concatMap (rule: mkSbRules rule.out rule.rules) rules;
  };
  outbounds = map (
    rule:
    selectorCfg
    // {
      tag = rule.out;
      default = "Direct";
    }
  ) rules;
  route = {
    rules =
      let
        mkSbRules = mylib.mkSbRules false;
      in
      lib.mkMerge (
        [ (lib.mkBefore (mkSbRules out [ { rule_set = [ "geoip-apple" ]; } ])) ]
        ++ (map (rule: mkSbRules rule.out rule.rules) rules)
      );
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
        {
          tag = "geosite-apple-update";
          url = "${urlPrefix}/geo/geosite/apple-update.srs";
        }
      ];
  };
}

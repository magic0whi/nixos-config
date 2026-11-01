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
  no_sniff_pri = pri * const.sb.routeSniffPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "Apple";
  super_rules = [
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
    ) super_rules;
    rules =
      let
        mkSbRules = mylib.mkSbRules true;
      in
      lib.mkOrder fakeip_pri (builtins.concatMap (rule: mkSbRules rule.out rule.rules) super_rules);
  };
  outbounds = map (
    rule:
    selectorCfg
    // {
      tag = rule.out;
      default = "Direct";
    }
  ) super_rules;
  route = {
    rules =
      let
        mkSbRules = mylib.mkSbRules false;
      in
      lib.mkMerge (
        [ (lib.mkOrder no_sniff_pri (mkSbRules out [ { rule_set = [ "geoip-apple" ]; } ])) ]
        ++ (map (rule: lib.mkOrder sniff_pri (mkSbRules rule.out rule.rules)) super_rules)
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

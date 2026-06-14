{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "Google";
  non_dns_rules = [ { rule_set = [ "geoip-google" ]; } ];
  rules = [
    {
      rule_set = [
        "geosite-google"
        "geosite-youtube"
      ];
    }
  ];
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
      default = "Default";
    }
  );
  route = {
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geoip-google";
          url = "${urlPrefix}/geo/geoip/google.srs";
        }
        {
          tag = "geosite-google";
          url = "${urlPrefix}/geo/geosite/google.srs";
        }
        {
          tag = "geosite-youtube";
          url = "${urlPrefix}/geo/geosite/youtube.srs";
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

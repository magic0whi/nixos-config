{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "Bilibili";
  rules = [ { rule_set = [ "geosite-bilibili" ]; } ];
in
{
  dns = {
    servers = lib.singleton (
      dnsServerCfg.direct
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
          tag = "geoip-bilibili";
          url = "${urlPrefix}/geo-lite/geoip/bilibili.srs";
        }
        {
          tag = "geosite-bilibili";
          url = "${urlPrefix}/geo/geosite/bilibili.srs";
        }
      ];
    rules = lib.mkMerge (
      let
        mkSbRules = mylib.mkSbRules false;
      in
      [
        (lib.mkBefore (mkSbRules out [ { rule_set = [ "geoip-bilibili" ]; } ]))
        (mkSbRules out rules)
      ]
    );
  };
}

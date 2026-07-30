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
  rules = [ { rule_set = [ "geosite-apple" ]; } ];
  out2 = "AppleUpdate";
  rules2 = [ { rule_set = [ "geosite-apple-update" ]; } ];
in
{
  dns = {
    servers = [
      (
        dnsServerCfg.default
        // {
          tag = out;
          detour = out;
        }
      )
      (
        dnsServerCfg.direct
        // {
          tag = out2;
          detour = out2;
        }
      )
    ];
    rules =
      let
        mkSbRules = mylib.mkSbRules true;
      in
      lib.mkMerge [
        (mkSbRules out2 rules2)
        (mkSbRules out rules)
      ];
  };
  outbounds = [
    (
      selectorCfg
      // {
        tag = out;
        default = "Direct";
      }
    )
    (
      selectorCfg
      // {
        tag = out2;
        default = "Block";
      }
    )
  ];
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
        {
          tag = "geosite-apple-update";
          url = "${urlPrefix}/geo/geosite/apple-update.srs";
        }
      ];
    rules = lib.mkMerge (
      let
        mkSbRules = mylib.mkSbRules false;
      in
      [
        (lib.mkBefore (mkSbRules out [ { rule_set = [ "geoip-apple" ]; } ]))
        (lib.mkOrder 800 (mkSbRules out2 rules2))
        (mkSbRules out rules)
      ]
    );
  };
}

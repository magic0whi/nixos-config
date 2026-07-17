{
  lib,
  mylib,
  ruleSetCfg,
  ...
}:
let
  defCfg.action = "reject";
  rules = [
    {
      domain_suffix = [
        "2miners.com"
        "donate.v2.xmrig"
        "supportxmr.com"
      ];
    }
    { rule_set = [ "geosite-apple-update" ]; }
  ];
in
{
  dns.rules = mylib.mkSbRules' true defCfg rules;
  route = {
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) (
        lib.singleton {
          tag = "geosite-apple-update";
          url = "${urlPrefix}/geo/geosite/apple-update.srs";
        }
      );
    rules = lib.mkMerge (
      let
        mkSbRules' = mylib.mkSbRules' false;
      in
      [
        (lib.mkBefore (
          mkSbRules' defCfg (
            lib.singleton {
              process_name = [
                "xmrig"
                "xmrig.exe"
              ];
            }
          )
        ))
        (lib.mkOrder 800 (mkSbRules' defCfg rules))
      ]
    );
  };
}

{
  lib,
  mylib,
  ruleSetCfg,
  ...
}:
let
  out = "Default";
  rules = [
    {
      domain_suffix = [
        "shuzijumin.com"
        "wenziwanka.com"
      ];
    }
    { rule_set = [ "geosite-gfw" ]; }
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
      map (rule_set: defaultCfg // rule_set) (
        lib.singleton {
          tag = "geosite-gfw";
          url = "${urlPrefix}/geo/geosite/gfw.srs";
        }
      );
  };
}

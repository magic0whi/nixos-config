{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "Game";
  super_rules = [
    {
      out = "Direct";
      rules = [ { rule_set = "geosite-category-game-platforms-download"; } ];
    }
    {
      inherit out;
      rules = [ { rule_set = "geosite-category-games"; } ];
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
    rules = builtins.concatMap (rules: mylib.mkSbRules true rules.out rules.rules) super_rules;
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
          tag = "geosite-category-games";
          url = "${urlPrefix}/geo/geosite/category-games.srs";
        }
        {
          tag = "geosite-category-game-platforms-download";
          url = "${urlPrefix}/geo/geosite/category-game-platforms-download.srs";
        }
      ];
    rules = builtins.concatMap (rules: mylib.mkSbRules false rules.out rules.rules) super_rules;
  };
}

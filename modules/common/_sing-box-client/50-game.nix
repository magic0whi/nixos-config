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
  realip_pri = pri * const.sb.dnsFakeIpPri;
  fakeip_pri = pri * (2000 - const.sb.dnsFakeIpPri) + const.sb.dnsFakeIpPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "Game";
  super_rules = [
    {
      pri = realip_pri;
      out = "Direct";
      rules = [ { rule_set = "geosite-category-game-platforms-download"; } ];
    }
    {
      pri = fakeip_pri;
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
    rules = lib.mkMerge (
      map (super_rule: lib.mkOrder super_rule.pri (mylib.mkSbRules true super_rule.out super_rule.rules)) super_rules
    );
  };
  outbounds = lib.singleton (
    selectorCfg
    // {
      tag = out;
      default = "Default";
    }
  );
  route = {
    rules = lib.mkOrder sniff_pri (builtins.concatMap (rules: mylib.mkSbRules false rules.out rules.rules) super_rules);
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
  };
}

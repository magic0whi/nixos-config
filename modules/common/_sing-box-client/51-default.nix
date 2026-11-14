{
  const,
  lib,
  mylib,
  ruleSetCfg,
  ...
}:
let
  pri = 0.51;
  fakeip_pri = pri * (2000 - const.sb.dnsFakeIpPri) + const.sb.dnsFakeIpPri;
  no_sniff_pri = pri * const.sb.routeSniffPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "Default";
  rules = [
    {
      domain = "cache.nixos.org";
      domain_suffix = [
        "redteago.com"
        "shuzijumin.com"
      ];
    }
    { rule_set = [ "geosite-gfw" ]; }
  ];
in
{
  dns.rules = lib.mkOrder fakeip_pri (mylib.mkSbRules true out rules);
  route = {
    rules =
      let
        mkSbRules = mylib.mkSbRules false;
      in
      lib.mkMerge [
        (lib.mkOrder no_sniff_pri (mkSbRules out [ { rule_set = [ "geoip-telegram" ]; } ]))
        (lib.mkOrder sniff_pri (mkSbRules out rules))
      ];
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geosite-gfw";
          url = "${urlPrefix}/geo/geosite/gfw.srs";
        }
        {
          tag = "geoip-telegram";
          url = "${urlPrefix}/geo/geoip/telegram.srs";
        }
      ];
  };
}

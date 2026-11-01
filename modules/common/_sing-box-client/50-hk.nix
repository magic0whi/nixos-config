{
  const,
  lib,
  mylib,
  ruleSetCfg,
  ...
}:
let
  pri = 0.50;
  fakeip_pri = pri * (2000 - const.sb.dnsFakeIpPri) + const.sb.dnsFakeIpPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "HongKong";
  rules = [
    { domain_suffix = "carousell.com.hk"; }
    {
      rule_set = [
        "geosite-hketgroup"
        "geosite-line"
      ];
    }
  ];
in
{
  dns.rules = lib.mkOrder fakeip_pri (mylib.mkSbRules true out rules);
  route = {
    rules = lib.mkOrder sniff_pri (mylib.mkSbRules false out rules);
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geosite-hketgroup";
          url = "${urlPrefix}/geo/geosite/hketgroup.srs";
        }
        {
          tag = "geosite-line";
          url = "${urlPrefix}/geo/geosite/line.srs";
        }
      ];
  };
}

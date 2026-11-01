{
  const,
  lib,
  mylib,
  ...
}:
let
  pri = 0.50;
  fakeip_pri = pri * (2000 - const.sb.dnsFakeIpPri) + const.sb.dnsFakeIpPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "UnitedStates";
  rules = lib.singleton {
    domain_suffix = [
      "t-mobile.com"
      "connectbyt-mobile.com"
      "redpocket.com"
    ];
  };
in
{
  dns.rules = lib.mkOrder fakeip_pri (mylib.mkSbRules true out rules);
  route.rules = lib.mkOrder sniff_pri (mylib.mkSbRules false out rules);
}

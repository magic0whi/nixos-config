{
  const,
  lib,
  mylib,
  ...
}:
let
  pri = 0.01;
  realip_pri = pri * const.sb.dnsFakeIpPri;
  # fakeip_pri = pri * (2000 - const.sb.dnsFakeIpPri) + const.sb.dnsFakeIpPri;
  no_sniff_pri = pri * const.sb.routeSniffPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  defCfg.action = "reject";
  rules = lib.singleton {
    domain_suffix = [
      "2miners.com"
      "donate.v2.xmrig"
      "supportxmr.com"
    ];
  };
in
{
  dns.rules = lib.mkOrder realip_pri (mylib.mkSbRules' true defCfg rules);
  route.rules =
    let
      mkSbRules' = mylib.mkSbRules' false;
    in
    lib.mkMerge [
      (lib.mkOrder no_sniff_pri (
        mkSbRules' defCfg (
          lib.singleton {
            process_name = [
              "xmrig"
              "xmrig.exe"
            ];
          }
        )
      ))
      (lib.mkOrder sniff_pri (mkSbRules' defCfg rules))
    ];
}

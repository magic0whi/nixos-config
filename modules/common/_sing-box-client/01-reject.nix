{ lib, mylib, ... }:
let
  pri = 0.01;
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
  dns.rules = lib.mkOrder (pri * 2000) (mylib.mkSbRules' true defCfg rules);
  route.rules =
    let
      mkSbRules' = mylib.mkSbRules' false;
    in
    lib.mkOrder (pri * 1000) (
      mkSbRules' defCfg (
        lib.singleton {
          process_name = [
            "xmrig"
            "xmrig.exe"
          ];
        }
      )
      ++ mkSbRules' defCfg rules
    );
}

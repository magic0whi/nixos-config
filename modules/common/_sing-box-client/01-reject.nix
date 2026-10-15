{ lib, mylib, ... }:
let
  pri = 0.01 * 2000;
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
  dns.rules = lib.mkOrder pri (mylib.mkSbRules' true defCfg rules);
  route.rules =
    let
      mkSbRules' = mylib.mkSbRules' false;
    in
    lib.mkOrder pri (
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

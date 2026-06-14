{
  lib,
  mylib,
  ...
}:
let
  defCfg = {
    action = "reject";
  };
  non_dns_rules = lib.singleton {
    process_name = [
      "xmrig"
      "xmrig.exe"
    ];
  };
  rules = [
    {
      domain_suffix = [
        "2miners.com"
        "donate.v2.xmrig"
        "supportxmr.com"
      ];
    }
  ];
in
{
  dns.rules = mylib.mkSbRules' true defCfg rules;
  route.rules = lib.mkMerge (
    let
      mkSbRules' = mylib.mkSbRules' false;
    in
    [
      (lib.mkBefore (mkSbRules' defCfg non_dns_rules))
      (lib.mkOrder 800 (mkSbRules' defCfg rules))
    ]
  );
}

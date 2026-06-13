{ lib, mylib, ... }:
let
  out = "Direct";
  bypass = [
    {
      process_name = [
        "easytier-core"
        "easytier-cli"
      ];
    }
    { ip_cidr = [ "10.0.0.0/24" ]; }
  ];
  rules = [
    {
      domain_suffix = [
        "stun.miwifi.com"
        "stun.chat.bilibili.com"
        "public.easytier.cn"
      ];
    }
  ];
in
{
  dns.rules = lib.mkBefore (mylib.mkSbRules true out rules);
  route.rules = lib.mkMerge (
    let
      mkSbRules = mylib.mkSbRules false;
    in
    [
      (lib.mkBefore (mkSbRules out bypass))
      (lib.mkOrder 875 (mkSbRules out rules))
    ]
  );
}

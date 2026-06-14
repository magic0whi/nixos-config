{ lib, mylib, ... }:
let
  out = "Direct";
  non_dns_rules = [
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
      (lib.mkBefore (mkSbRules out non_dns_rules))
      (lib.mkOrder 875 (mkSbRules out rules))
    ]
  );
}

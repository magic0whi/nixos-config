{ mylib, ... }:
let
  out = "Default";
  rules = [
    {
      domain_suffix = [
        "linux.do"
        "shuzijumin.com"
        "wenziwanka.com"
      ];
    }
  ];
in
{
  dns.rules = mylib.mkSbRules true out rules;
  route.rules = mylib.mkSbRules false out rules;
}

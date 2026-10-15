{
  lib,
  mylib,
  ...
}:
let
  out = "UnitedStates";
  rules = lib.singleton {
    domain_suffix = [
      "t-mobile.com"
      "connectbyt-mobile.com"
    ];
  };
in
{
  dns.rules = mylib.mkSbRules true out rules;
  route.rules = mylib.mkSbRules false out rules;
}

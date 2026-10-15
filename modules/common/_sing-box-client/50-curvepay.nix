{
  dnsServerCfg,
  lib,
  mylib,
  selectorCfg,
  ...
}:
let
  out = "CurvePay";
  rules = lib.singleton {
    domain_suffix = [
      "curve.app"
      "curve.com"
      "curve.api.kustomerapp.com"
      "imaginecurve.com"
    ];
  };
in
{
  dns = {
    servers = lib.singleton (
      dnsServerCfg.default
      // {
        tag = out;
        detour = out;
      }
    );
    rules = mylib.mkSbRules true out rules;
  };
  outbounds = lib.singleton (
    selectorCfg
    // {
      tag = out;
      default = "UnitedKingdom";
    }
  );
  route.rules = mylib.mkSbRules false out rules;
}

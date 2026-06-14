{
  dnsServerCfg,
  lib,
  mylib,
  selectorCfg,
  ...
}:
let
  out = "SumUp";
  rules = lib.singleton {
    domain_suffix = [
      "sumup.com"
      "sumup.io"
      "sumup.net"
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

{
  dnsServerCfg,
  lib,
  mylib,
  selectorCfg,
  ...
}:
let
  out = "Klarna";
  rules = lib.singleton {
    domain_suffix = [
      "klarna.app"
      "klarna.com"
      "klarnacdn.net"
      "klarnaevt.com"
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

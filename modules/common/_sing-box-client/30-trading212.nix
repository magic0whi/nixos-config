{
  dnsServerCfg,
  lib,
  mylib,
  selectorCfg,
  ...
}:
let
  out = "Trading212";
  rules = lib.singleton {
    domain_regex = ''trading212equities\.s3\.\S+\.amazonaws\.com'';
    domain_suffix = "trading212.com";
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

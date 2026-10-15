{
  dnsServerCfg,
  lib,
  mylib,
  selectorCfg,
  ...
}:
let
  out = "Coinbase";
  rules = lib.singleton {
    domain_suffix = [
      "coinbase.com"
      "wallet.elephant-blue.org"
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
      default = "Germany";
    }
  );
  route.rules = mylib.mkSbRules false out rules;
}

{
  dnsServerCfg,
  lib,
  mylib,
  selectorCfg,
  ...
}:
let
  out = "Default";
  rules = [ { domain_suffix = "wenziwanka.com"; } ];
in
{
  dns = {
    servers = lib.mkOrder 250 (
      lib.singleton (
        dnsServerCfg.default
        // {
          tag = out;
          detour = out;
        }
      )
    );
    rules = mylib.mkSbRules true out rules;
  };
  outbounds = lib.mkOrder 250 (
    lib.singleton (
      lib.mkMerge [
        (selectorCfg // { outbounds = lib.remove "Default" selectorCfg.outbounds; })
        {
          tag = "Default";
          default = "Auto";
        }
      ]
    )
  );
  route.rules = mylib.mkSbRules false out rules;
}

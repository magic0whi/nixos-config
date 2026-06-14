{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "Microsoft";
  rules = [ { rule_set = [ "geosite-microsoft" ]; } ];
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
      default = "Direct";
    }
  );
  route = {
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-microsoft";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/microsoft.srs";
      }
    );
    rules = mylib.mkSbRules false out rules;
  };
}

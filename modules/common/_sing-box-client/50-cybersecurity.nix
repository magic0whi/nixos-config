{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "Cybersecurity";
  rules = [
    { domain_suffix = [ "online-metrix.net" ]; }
    { rule_set = "geosite-hcaptcha"; }
  ];
in
{
  dns = {
    servers = lib.singleton (
      dnsServerCfg.direct
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
    rules = mylib.mkSbRules false out rules;
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-hcaptcha";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/hcaptcha.srs";
      }
    );
  };
}

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
    rules =
      let
        mkSbRules = mylib.mkSbRules false;
      in
      lib.mkMerge [
        (mkSbRules out rules)
        (lib.mkBefore (mkSbRules out [ { rule_set = [ "geoip-cloudflare" ]; } ]))
      ];
    rule_set =
      let
        inherit (ruleSetCfg) defaultCfg urlPrefix;
      in
      [
        (
          defaultCfg
          // {
            tag = "geoip-cloudflare";
            url = "${urlPrefix}/geo/geoip/cloudflare.srs";
          }
        )
        (
          defaultCfg
          // {
            tag = "geosite-hcaptcha";
            url = "${urlPrefix}/geo/geosite/hcaptcha.srs";
          }
        )
      ];
  };
}

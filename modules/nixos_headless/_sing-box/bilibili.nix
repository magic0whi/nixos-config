{
  lib,
  sharedRuleSetCfg,
  mylib,
  ...
}:
let
  out = "Bilibili";
  bypass = [ { rule_set = [ "geoip-bilibili" ]; } ];
  rules = [
    {
      outbound = "BiliBili";
      rule_set = [ "geosite-bilibili" ];
    }
  ];
in
{
  dns = {
    servers = [
      # The DNS server should accessable on direct
      {
        tag = "Bilibili";
        domain_resolver = "bootstrap";
        server = "dns.alidns.com";
        type = "tls";
      }
    ];
    rules = mylib.mkSbRules true out rules;
  };
  route = {
    rule_set =
      let
        inherit (sharedRuleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geoip-bilibili";
          url = "${urlPrefix}/geo-lite/geoip/bilibili.srs";
        }
        {
          tag = "geosite-bilibili";
          url = "${urlPrefix}/geo/geosite/bilibili.srs";
        }
      ];

    rules = lib.mkMerge (
      let
        mkSbRules = mylib.mkSbRules false;
      in
      [
        (lib.mkBefore (mkSbRules out bypass))
        (mkSbRules out rules)
      ]
    );
  };
}

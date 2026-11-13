{
  const,
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  pri = 0.50;
  fakeip_pri = pri * (2000 - const.sb.dnsFakeIpPri) + const.sb.dnsFakeIpPri;
  no_sniff_pri = pri * const.sb.routeSniffPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "Cybersecurity";
  rules = [
    {
      domain_suffix = [
        "awswaf.com" # AWS WAF: bot-control challenge / token SDK
        "eum-appdynamics.com" # Cisco AppDynamics: app performance monitoring
        "medallia.com" # Medallia: customer feedback surveys & experience analytics
        "online-metrix.net" # LexisNexis ThreatMetrix: device fingerprinting & fraud scoring
        "zimperium.com" # Zimperium: mobile threat defense / app anti-tamper SDK
        "cloudfront.com" # AWS CDN
      ];
    }
    {
      rule_set = [
        "geosite-cloudflare"
        "geosite-hcaptcha"
      ];
    }
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
    rules = lib.mkOrder fakeip_pri (mylib.mkSbRules true out rules);
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
        (lib.mkOrder sniff_pri (mkSbRules out rules))
        (lib.mkOrder no_sniff_pri (mkSbRules out [ { rule_set = [ "geoip-cloudflare" ]; } ]))
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
            tag = "geosite-cloudflare";
            url = "${urlPrefix}/geo/geosite/cloudflare.srs";
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

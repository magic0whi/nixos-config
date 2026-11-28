{
  const,
  lib,
  mylib,
  dnsServerCfg,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  pri = 0.51;
  fakeip_pri = pri * (2000 - const.sb.dnsFakeIpPri) + const.sb.dnsFakeIpPri;
  no_sniff_pri = pri * const.sb.routeSniffPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "Custom";
  rules = [
    {
      domain = [
        "cache.nixos.org"
        "repology.org"
      ];
      domain_suffix = [
        "redteago.com"
        "shuzijumin.com"
        "altstore.io"

        "braze-images.com" # Braze: in-app message image CDN

        # AWS CDN
        "cloudfront.com"
        "cloudfront.net"

        "cachix.org"
      ];
    }
    {
      rule_set = [
        "geosite-ctrip!cn"
        "geosite-gfw"
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
      default = "Default";
    }
  );
  route = {
    rules =
      let
        mkSbRules = mylib.mkSbRules false;
      in
      lib.mkMerge [
        (lib.mkOrder no_sniff_pri (mkSbRules out [ { rule_set = [ "geoip-telegram" ]; } ]))
        (lib.mkOrder sniff_pri (mkSbRules out rules))
      ];
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geosite-ctrip!cn";
          url = "${urlPrefix}/geo/geosite/ctrip@!cn.srs";
        }
        {
          tag = "geosite-gfw";
          url = "${urlPrefix}/geo/geosite/gfw.srs";
        }
        {
          tag = "geoip-telegram";
          url = "${urlPrefix}/geo/geoip/telegram.srs";
        }
      ];
  };
}

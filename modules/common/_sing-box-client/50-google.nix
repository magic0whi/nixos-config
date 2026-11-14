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
  # no_sniff_pri = pri * const.sb.routeSniffPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "Google";
  rules = lib.singleton {
    rule_set = [
      "geosite-google"
      "geosite-youtube"
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
        (lib.mkOrder
          # no_sniff_pri
          sniff_pri
          (mkSbRules out [ { rule_set = [ "geoip-google" ]; } ])
        )
        (lib.mkOrder sniff_pri (mkSbRules out rules))
      ];
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geoip-google";
          url = "${urlPrefix}/geo/geoip/google.srs";
        }
        {
          tag = "geosite-google";
          url = "${urlPrefix}/geo/geosite/google.srs";
        }
        {
          tag = "geosite-youtube";
          url = "${urlPrefix}/geo/geosite/youtube.srs";
        }
      ];
  };
}

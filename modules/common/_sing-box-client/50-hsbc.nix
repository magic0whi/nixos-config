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
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "HSBC";
  rules = [
    {
      domain_suffix = [
        "checkfreeweb.com" # HSBC US Bank-to-Bank
        "firstdata.com" # HSBC US credit card
        "d3ksttzjeov72n.cloudfront.net" # firstdata

        # Third-party services
        "adobesign.com" # Document sign
        "mdes.mastercard.com" # Mastercard MDES / 3-D Secure
        "liveperson.com" # LivePerson chat assets
        "tiqcdn.com" # Tealium tag manager
        "tealiumiq.com" # Tealium collect / visitor service
        "c-hsbc.lytics.io" # Lytics CDP (HSBC-specific)
        "walkme.com" # WalkMe in-app guidance
      ];
    }
    {
      rule_set = [
        "geosite-hsbc"
        "geosite-liveperson"
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
    rules = lib.mkOrder sniff_pri (mylib.mkSbRules false out rules);
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geosite-hsbc";
          url = "${urlPrefix}/geo/geosite/hsbc.srs";
        }
        {
          tag = "geosite-liveperson";
          url = "${urlPrefix}/geo/geosite/liveperson.srs";
        }
      ];
  };
}

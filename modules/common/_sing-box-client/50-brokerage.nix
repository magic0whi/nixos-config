{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "Brokerage";
  rules = lib.singleton {
    rule_set = [
      "geosite-ibkr"
      "geosite-schwab"
    ];
  };
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
        (lib.mkBefore (
          mkSbRules out (
            lib.singleton {
              rule_set = [
                "asn-ibkr-as9096"
                "asn-ibkr-as9468"
                "asn-ibkr-as27163"
                "asn-ibkr-as40711"
              ];
            }
          )
        ))

        (mkSbRules out rules)
      ];
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "asn-ibkr-as9096";
          url = "${urlPrefix}/asn/AS9096.srs";
        }
        {
          tag = "asn-ibkr-as9468";
          url = "${urlPrefix}/asn/AS9468.srs";
        }
        {
          tag = "asn-ibkr-as27163";
          url = "${urlPrefix}/asn/AS27163.srs";
        }
        {
          tag = "asn-ibkr-as40711";
          url = "${urlPrefix}/asn/AS40711.srs";
        }

        {
          tag = "geosite-schwab";
          url = "${urlPrefix}/geo/geosite/schwab.srs";
        }
        {
          tag = "geosite-ibkr";
          url = "${urlPrefix}/geo/geosite/ibkr.srs";
        }
      ];
  };
}

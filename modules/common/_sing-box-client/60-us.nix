{
  lib,
  mylib,
  ruleSetCfg,
  ...
}:
let
  out = "UnitedStates";
  rules = [
    {
      domain_suffix = [
        "wallet.coinbase.com"
        "wallet.elephant-blue.org"

        "t-mobile.com"
        "connectbyt-mobile.com"
      ];
    }

    { rule_set = [ "geosite-ibkr" ]; }
  ];
in
{
  dns.rules = mylib.mkSbRules true out rules;
  route = {
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
          tag = "geosite-ibkr";
          url = "${urlPrefix}/geo/geosite/ibkr.srs";
        }
      ];
    rules = lib.mkMerge (
      let
        mkSbRules = mylib.mkSbRules false;
      in
      [
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
      ]
    );
  };
}

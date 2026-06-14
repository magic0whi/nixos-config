{ mylib, ruleSetCfg, ... }:
let
  out = "UnitedKingdom";
  rules = [
    {
      domain = "moneyboxassets.blob.core.windows.net";
      domain_suffix = [
        # Credit Agency
        "clearscore.com"
        "creditkarma.co.uk"

        "experian.co.uk"
        "experianidentityservice.co.uk"
        "expcdn.co.uk"

        "equifax.co.uk"
        "equifax.com"

        # Banks
        "chase.co.uk"
        "chase.intl"
        "nutmeg.com"

        "monzo.com"
        "monzo-alt.net"

        "nationwide.co.uk"

        "tsb.co.uk"

        "zopa.com"

        # TechFi
        "jaja.co.uk"

        "yondercard.com"
        "yonder.com"

        "zable.co.uk"

        "withplum.com"

        "moneyboxapp.com"

        "chiphq.net"

        # CEx
        "backpack.exchange"
        "backpack.workers.dev"

        "neverless.com"

        # Brokerage
        "freetrade.io"
        "freetrade.app"

        # Transfer
        "remitly.com"
        "remitly.io"
        "remitly-3pjs.com"
        "remit.ly"

        "skrill.com"

        "lemfi.com"
        "lemonade.finance"
        "lemonadefi.app.link"

        "taptapsend.com"

        "westernunion.com"

        # Misc
        "truelayer.com"
        "yapily.com"
        "zimperium.com"
      ];
    }
    { rule_set = [ "geosite-wise" ]; }
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
          tag = "geosite-wise";
          url = "${urlPrefix}/geo/geosite/wise.srs";
        }
      ];
    rules = mylib.mkSbRules false out rules;
  };
}

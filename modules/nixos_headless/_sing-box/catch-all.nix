{ lib, mylib, ... }:
let
  out = "Direct";
  bypass = [ { rule_set = [ "geoip-cn" ]; } ];
  rules = [
    { protocol = "ssh"; }
    {
      domain_suffix = [
        # HK Finance
        "octopuscards.com"
        "octopus-cards.com"
        "octopus.com.hk"
        "airstarbank.com"
        "antbank.hk"
        "asia.ccb.com"
        "welab.bank"
        "za.group"

        "szgjgs.com"
        "gov.hk"
      ];
    }
    {
      rule_set = [
        "geosite-schwab"
        # "geosite-bilibili" # TODO
        "geosite-boc"
        "geosite-ccb"
        "geosite-icbc"
        "geosite-ifast"
        "geosite-alibaba@!cn"
        "geosite-tencent"
        "geosite-cn"
      ];
    }
  ];
in
{
  dns = {
    rules = lib.mkAfter (mylib.mkSbRules true out rules);
  };
  route.rules = lib.mkMerge (
    let
      mkSbRules = mylib.mkSbRules false;
    in
    [
      (lib.mkBefore (mkSbRules out bypass))
      (lib.mkAfter (mkSbRules out rules))
    ]
  );
}

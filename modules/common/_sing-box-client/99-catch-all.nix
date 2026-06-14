{
  lib,
  mylib,
  ruleSetCfg,
  ...
}:
let
  out = "Direct";
  non_dns_rules = [ { rule_set = [ "geoip-cn" ]; } ];
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
    rules = lib.mkOrder 2000 (mylib.mkSbRules true out rules);
  };
  route = {
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geosite-schwab";
          url = "${urlPrefix}/geo/geosite/schwab.srs";
        }
        # Banks (CN)
        {
          tag = "geosite-boc";
          url = "${urlPrefix}/geo/geosite/boc.srs";
        }
        {
          tag = "geosite-ccb";
          url = "${urlPrefix}/geo/geosite/ccb.srs";
        }
        {
          tag = "geosite-icbc";
          url = "${urlPrefix}/geo/geosite/icbc.srs";
        }

        {
          tag = "geosite-ifast";
          url = "${urlPrefix}/geo/geosite/ifast.srs";
        }

        {
          tag = "geosite-alibaba@!cn";
          url = "${urlPrefix}/geo/geosite/alibaba@!cn.srs";
        }
        {
          tag = "geosite-tencent";
          url = "${urlPrefix}/geo/geosite/tencent.srs";
        }

        # Catch-all
        {
          tag = "geoip-cn";
          url = "${urlPrefix}/geo/geoip/cn.srs";
        }
        {
          tag = "geosite-cn";
          url = "${urlPrefix}/geo/geosite/cn.srs";
        }
      ];
    rules = lib.mkMerge (
      let
        mkSbRules = mylib.mkSbRules false;
      in
      [
        (lib.mkBefore (mkSbRules out non_dns_rules))
        (lib.mkOrder 2000 (mkSbRules out rules))
      ]
    );
  };
}

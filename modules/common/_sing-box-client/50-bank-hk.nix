{
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "BankHK";
  rules = [
    {
      domain_suffix = [
        "octopuscards.com"
        "octopus-cards.com"
        "octopus.com.hk"

        "airstarbank.com"
        "antbank.hk"
        "asia.ccb.com"
        "welab.bank"
        "za.group"
      ];
    }
    {
      rule_set = [
        "geosite-boc!cn"
        "geosite-ccb!cn"
        "geosite-citic!cn"
        "geosite-icbc!cn"
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
    rules = mylib.mkSbRules false out rules;
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geosite-boc!cn";
          url = "${urlPrefix}/geo/geosite/boc@!cn.srs";
        }
        {
          tag = "geosite-ccb!cn";
          url = "${urlPrefix}/geo/geosite/ccb@!cn.srs";
        }
        {
          tag = "geosite-citic!cn";
          url = "${urlPrefix}/geo/geosite/citic@!cn.srs";
        }
        {
          tag = "geosite-icbc!cn";
          url = "${urlPrefix}/geo/geosite/icbc@!cn.srs";
        }
      ];
  };
}

# Shoud put before FakeIP; Clash Mode
{
  config,
  const,
  lib,
  mylib,
  ruleSetCfg,
  isLinux,
  isMobile,
  ...
}:
let
  out = "Direct";
  direct_process.rules = [
    # Libvirt
    # NOTE: `mylib.mkSbRules` doesn't support lib.mkIf attributes yet
    (lib.optionalAttrs (isLinux && (!isMobile) && config.virtualisation.libvirtd.enable) {
      source_ip_cidr = [ const.networking.libvirtNetCidr ];
    })
    # Tor & I2P
    {
      process_name = [
        "snowflake-pt-client"
        "snowflake-client.exe"
        "i2pd"
        "tor"
        "tor.exe"
      ];
    }
    { process_path_regex = [ ".*snowflake.*" ]; }

    # DNS utils
    { process_name = [ "doggo" ]; }

    # Misc
    {
      process_name = [
        "aria2c"
        "monerod"
        "syncthing"
        "syncthing.exe"
      ];
    }
    { process_path_regex = [ ".*localsend.*" ]; }
  ];
  rules = [
    { domain_suffix = [ "syncthing.net" ]; }
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
      ];
    }
  ];
in
{
  dns.rules = lib.mkBefore (mylib.mkSbRules true out rules);
  route = {
    rules =
      let
        mkSbRules = mylib.mkSbRules false;
      in
      lib.mkMerge [
        (lib.mkBefore (mkSbRules out direct_process.rules))
        (lib.mkOrder 875 (mkSbRules out rules))
        (lib.mkOrder 2000 (mkSbRules out [ { protocol = "ssh"; } ]))
      ];
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
      ];
  };
}

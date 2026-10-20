# Shoud put before FakeIP; Clash mode
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
  pri = 0.25;
  out = "Direct";
  rules = [
    { domain_suffix = [ "syncthing.net" ]; }
    {
      domain_suffix = [ "szgjgs.com" ];
    }
    {
      rule_set = [
        "geosite-ifast"
        "geosite-wise"
      ];
    }
  ];
in
{
  # Before FakeIP rule so all resolve to RealIP
  dns.rules = lib.mkOrder (pri * 2000) (mylib.mkSbRules true out rules);
  route = {
    rules =
      let
        mkSbRules = mylib.mkSbRules false;
      in
      lib.mkMerge [
        (lib.mkOrder (pri * 1000) (
          mkSbRules out (
            rules
            # BEGIN Processes rules
            ++ [
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
            ]
            # Libvirt
            ++ lib.optional (isLinux && (!isMobile) && config.virtualisation.libvirtd.enable) {
              source_ip_cidr = [ const.networking.libvirtNetCidr ];
            }
            # END Processes rules
          )
        ))

        (lib.mkOrder 2000 (mkSbRules out [ { protocol = "ssh"; } ]))
      ];
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geosite-ifast";
          url = "${urlPrefix}/geo/geosite/ifast.srs";
        }
      ];
  };
}

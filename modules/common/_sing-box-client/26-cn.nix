{
  config,
  const,
  lib,
  mylib,
  ruleSetCfg,
  isDarwin,
  ...
}:
let
  pri = 0.26;
  realip_pri = pri * const.sb.dnsFakeIpPri;
  no_sniff_pri = pri * const.sb.routeSniffPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "Direct";

  rules = [ { rule_set = [ "geosite-cn" ]; } ];
in
{
  dns.rules = lib.mkMerge [
    (lib.mkOrder realip_pri (mylib.mkSbRules true out rules))
    (lib.mkOrder (0.51 * const.sb.dnsFakeIpPri) (
      lib.optionals (config.services.sing-box.settings.dns.final != "Direct") [
        {
          action = "evaluate";
          server = out;
        }
        {
          match_response = true;
          rule_set = "geoip-cn";
          action = "respond";
        }
      ]
    ))
  ];
  route = {
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geoip-cn";
          url = "${urlPrefix}/geo/geoip/cn.srs";
        }
        {
          tag = "geosite-cn";
          url = "${urlPrefix}/geo/geosite/cn.srs";
        }
      ];
    rules =
      let
        mkSbRules = mylib.mkSbRules false;
      in
      lib.mkMerge [
        (lib.mkOrder no_sniff_pri (
          mkSbRules out (
            lib.singleton (
              # Bypass CN IPs but exclude DNS IP so sing-box can still hijack DNS request on macOS
              if isDarwin then
                {
                  type = "logical";
                  mode = "and";
                  rules = [
                    { rule_set = [ "geoip-cn" ]; }
                    {
                      invert = true;
                      ip_cidr = builtins.head config.networking.dns;
                    }
                  ];
                }
              else
                { rule_set = [ "geoip-cn" ]; }
            )
          )
        ))

        (lib.mkOrder sniff_pri (mkSbRules out rules))
      ];
  };
}

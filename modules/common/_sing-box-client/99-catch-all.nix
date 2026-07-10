{
  config,
  lib,
  mylib,
  ruleSetCfg,
  isDarwin,
  ...
}:
let
  out = "Direct";

  rules = [ { rule_set = [ "geosite-cn" ]; } ];
in
{
  dns.rules = lib.mkMerge [
    (lib.mkOrder 2000 (
      mylib.mkSbRules true out rules
      ++ [
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
    rules = lib.mkMerge (
      let
        mkSbRules = mylib.mkSbRules false;
      in
      [
        (lib.mkBefore (
          mkSbRules out [
            (
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
          ]
        ))
        (lib.mkOrder 2000 (mkSbRules out rules))
      ]
    );
  };
}

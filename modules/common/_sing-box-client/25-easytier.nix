{
  const,
  lib,
  mylib,
  ruleSetCfg,
  ...
}:
let
  out = "Direct";
  rules = [
    {
      domain_suffix = [
        "stun.chat.bilibili.com"
        "stun-heyuan-v6.easytier.cn"
        "public.easytier.cn"
      ];
    }
    { rule_set = "geosite-category-stun"; }
  ];
in
{
  dns.rules = lib.mkBefore (mylib.mkSbRules true out rules); # Before FakeIP rules
  route = {
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-category-stun";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/category-stun.srs";
      }
    );
    rules =
      let
        mkSbRules = mylib.mkSbRules false;
      in
      lib.mkMerge [
        (lib.mkBefore (
          mkSbRules out [
            { ip_cidr = [ "10.0.0.0/24" ]; }
            { port_range = "11010:11013"; }
            {
              process_name = [
                "easytier-core"
                "easytier-cli"
              ];
            }
          ]
          ++ (mkSbRules out rules)
        ))

        (lib.mkOrder (const.sb.routeSniffPri + 1) (
          lib.singleton {
            outbound = out;
            protocol = "stun";
          }
        ))
      ];
  };
}

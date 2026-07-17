{
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
    { port_range = "11010:11013"; }
    { rule_set = "geosite-category-stun"; }
  ];
in
{
  dns.rules = lib.mkBefore (mylib.mkSbRules true out rules);
  route = {
    rule_set = lib.singleton (
      ruleSetCfg.defaultCfg
      // {
        tag = "geosite-category-stun";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/category-stun.srs";
      }
    );
    rules = lib.mkMerge (
      let
        mkSbRules = mylib.mkSbRules false;
      in
      [
        (lib.mkBefore (
          mkSbRules out [
            {
              process_name = [
                "easytier-core"
                "easytier-cli"
              ];
            }
            { ip_cidr = [ "10.0.0.0/24" ]; }
          ]
        ))
        (lib.mkOrder 875 (
          lib.singleton {
            outbound = "Direct";
            protocol = "stun";
          }
          ++ mkSbRules out rules
        ))
      ]
    );
  };
}

# NOTE: use geosite-category-stun and `protocol = "stun"` may increase the risk of IP leaks (e.g. companies that use
# MetrixNet)
{
  # const,
  lib,
  mylib,
  # ruleSetCfg,
  ...
}:
let
  pri = 0.25;
  out = "Direct";
  rules = [
    {
      domain_suffix = [
        "stun.chat.bilibili.com"
        "stun-heyuan-v6.easytier.cn"
        "public.easytier.cn"
      ];
    }
    # { rule_set = "geosite-category-stun"; }
  ];
in
{
  dns.rules = lib.mkOrder (pri * 2000) (mylib.mkSbRules true out rules); # Before FakeIP rules
  route = {
    # rule_set = lib.singleton (
    #   ruleSetCfg.defaultCfg
    #   // {
    #     tag = "geosite-category-stun";
    #     url = "${ruleSetCfg.urlPrefix}/geo/geosite/category-stun.srs";
    #   }
    # );
    rules =
      let
        mkSbRules = mylib.mkSbRules false;
      in
      lib.mkMerge [
        (lib.mkOrder (pri * 1000) (
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

        # (lib.mkOrder (const.sb.routeSniffPri + 1) (
        #   lib.singleton {
        #     outbound = out;
        #     protocol = "stun";
        #   }
        # ))
      ];
  };
}

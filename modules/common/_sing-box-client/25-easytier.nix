# NOTE: use geosite-category-stun and `protocol = "stun"` may increase the risk of IP leaks (e.g. companies that use
# MetrixNet)
{
  const,
  lib,
  mylib,
  ruleSetCfg,
  ...
}:
let
  pri = 0.25;
  realip_pri = pri * const.sb.dnsFakeIpPri;
  no_sniff_pri = pri * const.sb.routeSniffPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "Direct";
  # All after the sniff rule
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
  dns.rules = lib.mkOrder realip_pri (mylib.mkSbRules true out rules);
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
        (lib.mkOrder no_sniff_pri (
          mkSbRules out [
            {
              # NOTE: `bypass` needs auto_redirect's pre-match, so keep it before the sniff rule, which stops pre-match for TCP
              # NOTE: sing-box will fallback to outbound if not auto-redirected
              action = "bypass";
              port_range = "11010:11013";
            }
            { ip_cidr = [ "10.0.0.0/24" ]; }
            {
              process_name = [
                "easytier-core"
                "easytier-cli"
              ];
            }
          ]
        ))

        (lib.mkOrder sniff_pri (
          lib.singleton {
            outbound = out;
            protocol = "stun";
          }
          ++ (mkSbRules out rules)
        ))
      ];
  };
}

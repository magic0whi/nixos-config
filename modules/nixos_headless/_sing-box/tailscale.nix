{
  lib,
  mylib,
  myvars,
  sharedRuleSetCfg,
  ...
}:
let
  bypass = {
    out = "Direct";
    rules = lib.singleton { process_path_regex = [ ".*tailscaled.*" ]; };
  };
  super_rules = [
    {
      out = "Tailscale";
      rules = [
        {
          ip_cidr = [
            "100.64.0.0/10"
            "fd7a:115c:a1e0::/48"
          ];
        }
        {
          domain_suffix = [
            "ts.net"
            "100.in-addr.arpa"
            "0.e.1.a.c.5.1.1.a.7.d.f.ip6.arpa"
          ];
        }
      ];
    }

    # STUN needs real ip
    {
      out = "Direct";
      rules = lib.singleton { rule_set = "geosite-tailscale"; }; # NOTE: geosite-tailscale has "ts.net"
    }
  ];
  my_domains.rules = lib.singleton { domain_suffix = myvars.domain; };
in
{
  dns = {
    servers = [
      {
        tag = "Tailscale";
        type = "tailscale";
        endpoint = "Tailscale";
      }
      {
        tag = "myNs";
        type = "tls";
        detour = "Tailscale";
        server = (builtins.head myvars.networking.hostAddrs.${myvars.networking.findHost "ns1"}).ipv4;
        tls.server_name = "ns1.${myvars.domain}";
      }
    ];
    rules =
      let
        mkSbRules = mylib.mkSbRules true;
      in
      lib.mkBefore (
        lib.flatten (map (rules: mkSbRules rules.out rules.rules) super_rules) ++ mkSbRules "myNs" my_domains.rules
      );
  };
  route = {
    rule_set = lib.singleton (
      sharedRuleSetCfg.defaultCfg
      // {
        tag = "geosite-tailscale";
        url = "${sharedRuleSetCfg.urlPrefix}/geo/geosite/tailscale.srs";
      }
    );
    rules = lib.mkMerge (
      let
        mkSbRules = mylib.mkSbRules false;
      in
      [
        (lib.mkBefore (mkSbRules bypass.out bypass.rules))
        # After sniff, dns hijack, clash modes, before default
        (lib.mkOrder 875 (
          lib.flatten (map (rules: mkSbRules rules.out rules.rules) super_rules) ++ mkSbRules "Tailscale" my_domains.rules
        ))
      ]
    );
  };
}

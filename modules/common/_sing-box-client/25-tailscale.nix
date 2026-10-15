{
  config,
  const,
  isMobile,
  lib,
  mylib,
  ruleSetCfg,
  ...
}:
let
  out = "Tailscale";
  rules = {
    default =
      lib.optional isMobile {
        inherit out;
        rules = lib.singleton {
          domain_suffix = [
            "ts.net" # NOTE: Must before geosite-tailscale
            "100.in-addr.arpa"
            "0.e.1.a.c.5.1.1.a.7.d.f.ip6.arpa"
          ];
        };
      }
      # STUN needs real ip
      ++ lib.singleton {
        out = "Direct";
        rules = lib.singleton { rule_set = "geosite-tailscale"; }; # NOTE: geosite-tailscale has "ts.net"
      };
    my_domain = lib.optional isMobile { domain_suffix = const.domain; };
  };
in
lib.mkMerge [
  # I run tailscaled on Darwin and Linux, so Tailscale endpoint only required on mobile devices
  (lib.mkIf isMobile {
    endpoints = lib.singleton {
      tag = out;
      type = "tailscale";
      auth_key._secret = config.sops.secrets.sb_ts_auth_key.path;
      accept_routes = true;
      # system_interface = true;
    };
  })
  {
    dns = {
      servers = lib.mkBefore (
        lib.optionals isMobile [
          {
            tag = out;
            type = "tailscale";
            endpoint = out;
          }
          {
            tag = "myNs";
            type = "tls";
            detour = out;
            server = const.networking.allHostAddrs.${const.networking.findFirstHostBySubdomain "ns1"}.tailscale.ipv4NoCidr;
            tls.server_name = "ns1.${const.domain}";
          }
        ]
      );
      rules =
        let
          mkSbRules = mylib.mkSbRules true;
        in
        lib.mkBefore (
          builtins.concatMap (_rules: mkSbRules _rules.out _rules.rules) rules.default ++ mkSbRules "myNs" rules.my_domain
        );
    };
    route = {
      rule_set = lib.singleton (
        ruleSetCfg.defaultCfg
        // {
          tag = "geosite-tailscale";
          url = "${ruleSetCfg.urlPrefix}/geo/geosite/tailscale.srs";
        }
      );
      rules =
        let
          mkSbRules = mylib.mkSbRules false;
        in
        lib.mkBefore (
          mkSbRules "Direct" [
            { process_path_regex = [ ".*tailscaled.*" ]; }
            {
              ip_cidr = [
                "100.64.0.0/10"
                "fd7a:115c:a1e0::/48"
              ];
            }
          ]
          ++ (builtins.concatMap (rules: mkSbRules rules.out rules.rules) rules.default ++ mkSbRules out rules.my_domain)
        );
    };
  }
]

{
  config,
  lib,
  mylib,
  myvars,
  ruleSetCfg,
  isDarwin,
  isMobile,
  ...
}:
let
  out = "Tailscale";
  non_dns_rules = {
    out = "Direct";
    rules = [
      { process_path_regex = [ ".*tailscaled.*" ]; }
      {
        ip_cidr = [
          "100.64.0.0/10"
          "fd7a:115c:a1e0::/48"
        ];
      }
    ];
  };
  super_rules =
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
  my_domains.rules = lib.optional (isDarwin || isMobile) { domain_suffix = myvars.domain; };
in
lib.mkMerge [
  # I use tailscaled on darwin and linux, so tailscale endpoint only required on mobile devices
  (lib.mkIf isMobile {
    endpoints = [
      {
        tag = out;
        type = "tailscale";
        auth_key._secret = config.sops.secrets.sb_ts_auth_key.path;
        accept_routes = true;
        # system_interface = true;
      }
    ];
  })
  {
    dns = {
      servers =
        lib.optional isMobile {
          tag = out;
          type = "tailscale";
          endpoint = out;
        }
        ++ lib.optional (isDarwin || isMobile) {
          tag = "myNs";
          type = "tls";
          detour = if isDarwin then "Default" else out; # Query through tailscaled on Darwin
          server = (builtins.head myvars.networking.hostAddrs.${myvars.networking.findHost "ns1"}).ipv4;
          tls.server_name = "ns1.${myvars.domain}";
        };
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
        ruleSetCfg.defaultCfg
        // {
          tag = "geosite-tailscale";
          url = "${ruleSetCfg.urlPrefix}/geo/geosite/tailscale.srs";
        }
      );
      rules = lib.mkMerge (
        let
          mkSbRules = mylib.mkSbRules false;
        in
        [
          (lib.mkBefore (mkSbRules non_dns_rules.out non_dns_rules.rules))
          (lib.flatten (map (rules: mkSbRules rules.out rules.rules) super_rules) ++ mkSbRules out my_domains.rules)
        ]
      );
    };
  }
]

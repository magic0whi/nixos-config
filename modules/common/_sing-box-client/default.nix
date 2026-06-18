{
  config,
  lib,
  mylib,
  myvars,
  pkgs,
  isDarwin ? pkgs.stdenv.isDarwin,
  isLinux ? pkgs.stdenv.isLinux,
  isMobile ? false,
}:
let
  shared_cfg = {
    selectorCfg = {
      type = "selector";
      outbounds = [
        "Direct"
        "Default"
        "Auto"
      ]
      # Regions
      ++ (map (outbound: outbound.tag)
        (import ./10-regions.nix {
          dnsServerCfg = null;
          lib = null;
        }).outbounds
      );
    };
    dnsServerCfg = {
      default = {
        server = "8.8.8.8";
        type = "tls";
      };
      direct = {
        server = "dns.alidns.com";
        type = "tls";
        domain_resolver = "Bootstrap";
      };
    };
  };
in
lib.mkMerge (
  [
    (lib.mkIf (isMobile && isLinux) {
      certificate.certificate = [ (builtins.readFile "${myvars.secretsDir}/proteus_ca.pub.pem") ];
    })
    {
      log = {
        level = "warn";
        timestamp = false;
      };
      dns = {
        final = "Default";
        servers = lib.mkOrder 250 [
          {
            tag = "FakeIP";
            type = "fakeip";
            inet4_range = "198.18.0.0/15";
            inet6_range = "fc00::/18";
          }
          {
            tag = "Bootstrap";
            type = "udp";
            server = "223.5.5.5";
          }
          {
            tag = "Direct";
            type = "tls";
            server = "dns.alidns.com";
            domain_resolver = "Bootstrap";
          }
          (
            shared_cfg.dnsServerCfg.default
            // {
              tag = "Default";
              detour = "Default";
            }
          )
        ];
        # The default rule uses the following matching logic:
        # (domain || domain_suffix || domain_keyword || domain_regex || geosite) &&
        # (port || port_range) &&
        # (source_geoip || source_ip_cidr ｜｜ source_ip_is_private) &&
        # (source_port || source_port_range) &&
        # other fields
        # Ref: https://sing-box.sagernet.org/configuration/dns/rule/#default-fields
        rules = lib.mkMerge [
          # FaleIP; Clash mode
          (lib.mkOrder 750 [
            # Let global & direct mode get RealIP
            {
              server = "Default";
              clash_mode = "global";
            }
            {
              server = "Direct";
              clash_mode = "direct";
            }
            {
              server = "FakeIP";
              query_type = [
                "A"
                "AAAA"
              ];
            }
          ])
        ];
      };
      experimental = {
        cache_file = {
          enabled = true;
          store_fakeip = true;
          store_dns = true;
        };
        clash_api = {
          default_mode = "rule";
          external_controller = "127.0.0.1:9091";
          external_ui = "ui";
          external_ui_download_detour = "Auto";
          external_ui_download_url = "https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip";
          secret = "";
        };
      };
      inbounds = [
        {
          listen = "127.0.0.1";
          listen_port = 2080;
          tag = "Mixed";
          type = "mixed";
        }
        (lib.mkMerge [
          # darwin only allow naming of the form "utun*"
          (lib.mkIf (!isDarwin) { interface_name = "sing0"; })
          (lib.mkIf isLinux { auto_redirect = true; })
          (lib.mkIf (!isMobile) {
            # sing-box will automatically bypass local NIC addresses to nftables with @inet4_local_address_set and
            # @inet6_local_address_set address set. NOTE: automatically added rules don't bypass DNS hijack
            route_exclude_address = [
              # Tailscale has CIDR set to /32 /128, so I need to bypass correct CIDR maually
              "100.64.0.0/10"
              "fd7a:115c:a1e0::/48"
              # I have custom NS setup, so I still need to specify here to prevent sing-box hijack my NS queries
              "10.0.0.0/24"
              "fdfe:dcba:9877::2/64"
            ];
          })
          {
            tag = "Tun";
            type = "tun";
            address = [
              "172.31.255.253/30"
              "fdfe:dcba:9876::1/126"
            ];
            stack = "gvisor";
            auto_route = true;
            # strict_route = true;
          }
        ])
      ];
      outbounds = lib.mkOrder 250 [
        {
          tag = "Direct";
          type = "direct";
        }
        (
          (shared_cfg.selectorCfg // { outbounds = lib.remove "Default" shared_cfg.selectorCfg.outbounds; })
          // {
            tag = "Default";
            default = "Auto";
          }
        )
      ];
      route = {
        auto_detect_interface = lib.mkDefault true;
        default_domain_resolver = "Bootstrap";
        final = "Default";
        # The default rule uses the following matching logic:
        # (domain || domain_suffix || domain_keyword || domain_regex || geosite || geoip || ip_cidr || ip_is_private) &&
        # (port || port_range) &&
        # (source_geoip || source_ip_cidr || source_ip_is_private) &&
        # (source_port || source_port_range) &&
        # other fields
        # Ref: https://sing-box.sagernet.org/configuration/route/rule/#default-fields
        rules = lib.mkOrder 750 [
          # https://sing-box.sagernet.org/configuration/route/sniff/
          {
            action = "sniff";
            inbound = [
              "Tun"
              "Mixed"
            ];
          }

          {
            action = "hijack-dns";
            mode = "or";
            rules = [
              { port = 53; }
              { protocol = "dns"; }
            ];
            type = "logical";
          }

          {
            clash_mode = "global";
            outbound = "Default";
          }
          {
            clash_mode = "direct";
            outbound = "Direct";
          }
        ];
      };
    }
  ]
  # Separate complex config to modular parts
  ++ map (
    file:
    import file (
      {
        inherit
          config
          lib
          mylib
          myvars
          isDarwin
          isLinux
          isMobile
          ;
      }
      // myvars.sb
      // shared_cfg
    )
  ) (mylib.scanPath ./.)
)

args@{
  lib,
  mylib,
  const,
  config,
  pkgs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  isLinux ? pkgs.stdenv.hostPlatform.isLinux,
  isMobile ? false,
  isServer ? false,
  isRouter ? false,
  ...
}:
let
  # domestic_dns = "dns.alidns.com";
  domestic_dns = "sm2.doh.pub";

  shared_cfg = {
    selectorCfg = {
      type = "selector";
      outbounds = [
        "Direct"
        "Default"
        "Auto"
        "Block"
      ]
      # Regions
      ++ (map (outbound: outbound.tag)
        (import ./11-regions.nix {
          dnsServerCfg = null;
          inherit lib;
        }).outbounds.content
      );
    };
    dnsServerCfg = {
      default = {
        server = "8.8.8.8";
        type = "tls";
      };
      direct = {
        server = domestic_dns;
        type = "https";
        domain_resolver = "Bootstrap";
      };
    };
  };
in
lib.mkMerge (
  [
    (lib.mkIf (isMobile && isLinux) {
      certificate.certificate = [ (builtins.readFile "${const.secretsDir}/proteus_ca.pub.pem") ];
    })
    {
      log = {
        level = "warn";
        timestamp = false;
      };
      dns = {
        final = if isRouter then "Direct" else "Default";
        servers = lib.mkOrder (0.1 * 2000) [
          {
            tag = "FakeIP";
            type = "fakeip";
            inet4_range = "198.18.0.0/15";
            inet6_range = "2001:0002::/48";
          }
          {
            tag = "Bootstrap";
            type = "udp";
            server = "223.5.5.5";
          }

          (shared_cfg.dnsServerCfg.direct // { tag = "Direct"; })

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
        # FakeIP; Clash mode
        rules = lib.mkMerge [
          # Set before FakeIP rule to let global & direct mode get RealIP
          (lib.mkOrder 0 [
            {
              server = "Default";
              clash_mode = "global";
            }
            {
              server = "Direct";
              clash_mode = "direct";
            }
          ])
          (lib.mkOrder const.sb.dnsFakeIpPri [
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
            # Also note: these only exclude the target IP CIDR, if you add libvirt's net, DNS queries sent from VMs
            # would still be hijacked by sing-box
            route_exclude_address = [
              # I have custom NS setup, so I still need to specify here to prevent sing-box hijack my NS queries
              "10.0.0.0/24"
              "fdfe:dcba:9877::/64"
            ]
            # Don't hijack DNS query to local NS
            ++ (
              let
                hostAddrs = config.vars.hostAddrs.${config.networking.hostName};
              in
              lib.optional (hostAddrs ? wire && hostAddrs.wire.ipv4 != null) hostAddrs.wire.ipv4
            )
            # I have split DNS listen on 172.17.0.1 when docker is enabled
            ++ lib.optional (config.virtualisation.docker.enable or false) "172.17.0.1/32";
          })
          # FakeIP-only mode
          (lib.mkIf isServer {
            route_address =
              let
                fakeip_server = lib.findFirst (server: server.type == "fakeip") { } config.services.sing-box.settings.dns.servers;
              in
              [
                fakeip_server.inet4_range
                fakeip_server.inet6_range
              ];
          })
          (lib.mkIf (!isMobile && (config.services.aria2.enable or false)) {
            exclude_uid = [ config.users.users.aria2.uid ];
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

            # One UDP NAT mapping per (source, destination IP) instead of per source. Phones behind a NAT router on
            # different carriers can all reach the gateway as e.g. 192.168.1.22:4500, so with the default
            # `endpoint_independent` their VoWiFi (IPsec NAT-T) sessions to different ePDGs share a mapping and only one
            # stays up. Cost: STUN sees a per-destination port, so UDP hole punching from LAN devices relays more often
            udp_mapping = if isRouter then "address_dependent" else "endpoint_independent";
          }
        ])
      ];
      outbounds = lib.mkOrder (0.1 * 2000 - 1) [
        {
          tag = "Direct";
          type = "direct";
        }
        {
          tag = "Block";
          type = "block";
        }
        (
          (shared_cfg.selectorCfg // { outbounds = lib.remove "Default" shared_cfg.selectorCfg.outbounds; })
          // {
            tag = "Default";
            default = "Auto";
          }
        )
      ];
      http_clients = lib.singleton {
        tag = "Default";
        detour = "Default";
      };
      route = {
        auto_detect_interface = lib.mkDefault true;
        default_domain_resolver = "Bootstrap";
        final = if isRouter then "Direct" else "Default";
        # The default rule uses the following matching logic:
        # (domain || domain_suffix || domain_keyword || domain_regex || geosite || geoip || ip_cidr || ip_is_private) &&
        # (port || port_range) &&
        # (source_geoip || source_ip_cidr || source_ip_is_private) &&
        # (source_port || source_port_range) &&
        # other fields
        # Ref: https://sing-box.sagernet.org/configuration/route/rule/#default-fields
        #
        # IP/process/port rules go before the sniff rule (`no_sniff_pri`), domain rules after it (`sniff_pri`);
        # DNS hijack comes last
        rules = lib.mkMerge [
          # https://sing-box.sagernet.org/configuration/route/sniff/
          (lib.mkOrder 0 [
            {
              clash_mode = "direct";
              outbound = "Direct";
            }
            {
              clash_mode = "global";
              outbound = "Default";
            }
          ])

          (lib.mkOrder (const.sb.routeSniffPri) (
            lib.singleton {
              action = "sniff";
              inbound = [
                "Tun"
                "Mixed"
              ];
            }
          ))

          (lib.mkOrder (0.99 * 2000) [
            {
              action = "hijack-dns";
              type = "logical";
              mode = "or";
              rules = [
                { port = 53; }
                { protocol = "dns"; }
              ];
            }
          ])
        ];
      };
    }
  ]
  # Separate complex config to modular parts
  # NOTE: `args` only has arguments from what this files being imported
  ++ map (
    file:
    import file (
      {
        inherit
          isDarwin
          isLinux
          isMobile
          isServer
          isRouter
          ;
      }
      // args
      // const.sb
      // shared_cfg
    )
  ) (mylib.scanPath ./.)
)

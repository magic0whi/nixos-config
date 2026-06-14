{
  config,
  lib,
  mylib,
  myvars,
  ...
}:
{
  sops.secrets =
    let
      sopsFile = "${myvars.secretsDir}/common.sops.yaml";
      restartUnits = [ "sing-box.service" ];
    in
    {
      # "sb_client_linux.json" = {
      #   sopsFile = "${myvars.secretsDir}/sb_client_linux.json.sops";
      #   format = "binary";
      #   restartUnits = [ "sing-box.service" ];
      # };
      sb_nodes_password = { inherit sopsFile restartUnits; };
      sb_nodes_public_key = { inherit sopsFile restartUnits; };
      sb_nodes_short_id = { inherit sopsFile restartUnits; };
      sb_nodes_server_name = { inherit sopsFile restartUnits; };
      sb_nodes_Proteus-NixOS-0 = { inherit sopsFile restartUnits; };
      sb_nodes_Proteus-NixOS-4 = { inherit sopsFile restartUnits; };
      sb_nodes_Proteus-NixOS-5 = { inherit sopsFile restartUnits; };
      sb_ts_auth_key = { inherit sopsFile restartUnits; };
    };
  networking.firewall.trustedInterfaces = [ "sing0" ];
  services.sing-box = {
    enable = true;
    settings =
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
              (import ./_sing-box/10-regions.nix {
                dnsServerCfg = null;
                lib = null;
              }).outbounds
            );
          };
          ruleSetCfg = {
            urlPrefix = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing";
            defaultCfg = {
              format = "binary";
              download_detour = "Auto";
              type = "remote";
            };
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
          # Full config.json encryption
          # {
          #   _secret = config.sops.secrets."sb_client_linux.json".path;
          #   quote = false;
          # }
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
                store_rdrc = true;
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
              {
                tag = "Tun";
                type = "tun";
                address = [
                  "172.19.0.1/30"
                  "fdfe:dcba:9876::1/126"
                ];
                stack = "gvisor";
                auto_route = true;
                strict_route = false;
                interface_name = "sing0";
                auto_redirect = true;
                route_exclude_address = [
                  "10.0.0.0/24"
                  "fdfe:dcba:9877::/64"
                ];
              }
            ];
            outbounds = lib.mkOrder 250 [
              {
                tag = "Direct";
                type = "direct";
              }
            ];
            route = {
              auto_detect_interface = true;
              default_domain_resolver = "Direct";
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
                ;
            }
            // shared_cfg
          )
        ) (mylib.scanPath ./_sing-box)
      );
  };
}

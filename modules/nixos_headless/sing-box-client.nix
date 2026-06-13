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
        # Custom rule sets
        reject = {
          process_name = [
            "xmrig"
            "xmrig.exe"
          ];
          domain_suffix = [
            "2miners.com"
            "donate.v2.xmrig"
            "supportxmr.com"
          ];
        };
        # default.domain_suffix = [ "wenziwanka.com" ];
        sharedSelectorCfg = {
          type = "selector";
          outbounds = [
            "Direct"
            "Default"
            "Auto"
            # "Germany"
            "HongKong"
            "UnitedKingdom"
            "UnitedStates"
            "Others"
          ];
        };
        sharedRuleSetCfg = {
          urlPrefix = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing";
          defaultCfg = {
            format = "binary";
            download_detour = "Auto";
            type = "remote";
          };
        };
        sharedDnsServerCfg = {
          server = "8.8.8.8";
          type = "tls";
        };
      in
      lib.mkMerge (
        [
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
              servers = [
                {
                  tag = "fakeip";
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
                {
                  tag = "Default";
                  type = "tls";
                  server = "8.8.8.8";
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
                # Reject
                (lib.mapAttrsToList (name: val: {
                  action = "reject";
                  ${name} = val;
                }) reject)

                # FaleIP; Clash mode
                (lib.mkOrder 750 [
                  {
                    server = "fakeip";
                    query_type = [
                      "A"
                      "AAAA"
                    ];
                  }
                  {
                    server = "Direct";
                    clash_mode = "direct";
                  }
                  {
                    server = "Default";
                    clash_mode = "global";
                  }
                ])
              ];
            };
            endpoints = [
              {
                accept_routes = true;
                auth_key._secret = config.sops.secrets.sb_ts_auth_key.path;
                system_interface = true;
                tag = "Tailscale";
                type = "tailscale";
              }
            ];
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
                tag = "mixed-in";
                type = "mixed";
              }
            ];
            outbounds =
              let
                nodes =
                  map
                    (
                      node:
                      {
                        server_port = 443;
                        password._secret = config.sops.secrets.sb_nodes_password.path;
                        tls = {
                          enabled = true;
                          reality = {
                            enabled = true;
                            public_key._secret = config.sops.secrets.sb_nodes_public_key.path;
                            short_id._secret = config.sops.secrets.sb_nodes_short_id.path;
                          };
                          server_name._secret = config.sops.secrets.sb_nodes_server_name.path;
                          utls = {
                            enabled = true;
                            fingerprint = "chrome";
                          };
                        };
                        type = "anytls";
                      }
                      // node
                    )
                    [
                      {
                        tag = "Proteus-NixOS-0";
                        server._secret = config.sops.secrets.sb_nodes_Proteus-NixOS-0.path;
                      }
                      {
                        tag = "Proteus-NixOS-4";
                        server._secret = config.sops.secrets.sb_nodes_Proteus-NixOS-4.path;
                      }
                      {
                        tag = "Proteus-NixOS-5";
                        server._secret = config.sops.secrets.sb_nodes_Proteus-NixOS-5.path;
                      }
                    ]

                  ++ lib.singleton {
                    tag = "Socks5";
                    type = "socks";
                    detour = "Auto";
                    server = "127.0.0.1";
                    server_port = 1080;
                    username = "1111111111";
                    password = "2222222222";
                    udp_over_tcp = false;
                    version = "5";
                  };
              in
              nodes
              ++ [
                {
                  tag = "Direct";
                  type = "direct";
                }
                (lib.mkMerge [
                  (sharedSelectorCfg // { outbounds = lib.remove "Default" sharedSelectorCfg.outbounds; })
                  {
                    tag = "Default";
                    default = "Auto";
                  }
                ])
                {
                  tag = "Auto";
                  type = "urltest";
                  interval = "10m";
                  tolerance = 50;
                  url = "http://www.gstatic.com/generate_204";
                  outbounds = map (node: node.tag) nodes;
                }
              ]

              ++ [
                {
                  tag = "HongKong";
                  type = "selector";
                  outbounds = [ "Proteus-NixOS-5" ];
                }
                {
                  tag = "UnitedStates";
                  type = "selector";
                  outbounds = [ "Proteus-NixOS-0" ];
                }
                {
                  tag = "UnitedKingdom";
                  type = "selector";
                  outbounds = [ "Proteus-NixOS-4" ];
                }
                # {
                #   outbounds = [ ];
                #   type = "selector";
                #   tag = "Germany";
                # }
                {
                  tag = "Others";
                  type = "selector";
                  outbounds = [ "Socks5" ];
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
              rules = lib.mkMerge [
                (lib.mkOrder 750 [
                  # https://sing-box.sagernet.org/configuration/route/sniff/
                  {
                    action = "sniff";
                    inbound = [
                      "tun-in"
                      "mixed-in"
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
                ])
              ];
            };
          }
        ]
        ++ map (
          file:
          import file {
            inherit
              lib
              mylib
              myvars
              sharedSelectorCfg
              sharedRuleSetCfg
              sharedDnsServerCfg
              ;
          }
        ) (mylib.scanPath ./_sing-box)
      );
  };
}

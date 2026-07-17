{
  config,
  dnsServerCfg,
  lib,
  pkgs,
  ...
}:
let
  isSubscribeEnabled = config.services.sing-box.subscribe.enable;
  outbounds =
    (lib.evalModules {
      modules = lib.singleton {
        options.outbounds = lib.mkOption {
          type =
            with lib.types;
            listOf (submodule {
              freeformType = (pkgs.formats.json { }).type;
            });
          default = [
            (lib.mkMerge [
              {
                tag = "HongKong";
                type = "selector";
                outbounds = [ "Proteus-NixOS-5" ];
              }
              (lib.mkIf isSubscribeEnabled {
                outbounds = [ "{all}" ];
                filter = lib.singleton {
                  action = "include";
                  keywords = [ "🇭🇰|HK|hk|香港|港|HongKong" ];
                };
              })
            ])
            (lib.mkMerge [
              {
                tag = "UnitedKingdom";
                type = "selector";
                outbounds = [ "Proteus-NixOS-4" ];
              }
              (lib.mkIf isSubscribeEnabled {
                outbounds = [ "{all}" ];
                filter = lib.singleton {
                  action = "include";
                  keywords = [ "🇬🇧|UK|uk|英国|英|United Kingdom" ];
                };
              })
            ])
            (lib.mkMerge [
              {
                tag = "UnitedStates";
                type = "selector";
                outbounds = [
                  "Proteus-NixOS-0"
                  "Proteus-NixOS-1"
                ];
              }
              (lib.mkIf isSubscribeEnabled {
                outbounds = [ "{all}" ];
                filter = lib.singleton {
                  action = "include";
                  keywords = [ "🇺🇸|US|us|美国|美|United States" ];
                };
              })
            ])
            # (lib.mkMerge [
            #   {
            #     tag = "Taiwan";
            #     type = "selector";
            #     outbounds = [ ];
            #   }
            #   (lib.mkIf isSubscribeEnabled {
            #     outbounds = [ "{all}" ];
            #     filter = lib.singleton {
            #       action = "include";
            #       keywords = [ "🇹🇼|TW|tw|台湾|臺灣|台|Taiwan" ];
            #     };
            #   })
            # ])
            # (lib.mkMerge [
            #   {
            #     tag = "Singapore";
            #     type = "selector";
            #     outbounds = [ ];
            #   }
            #   (lib.mkIf isSubscribeEnabled {
            #     outbounds = [ "{all}" ];
            #     filter = lib.singleton {
            #       action = "include";
            #       keywords = [ "🇸🇬|SG|sg|新加坡|狮|Singapore" ];
            #     };
            #   })
            # ])
            (lib.mkMerge [
              {
                tag = "Japan";
                type = "selector";
                outbounds = [ "Proteus-NixOS-3" ];
              }
              (lib.mkIf isSubscribeEnabled {
                outbounds = [ "{all}" ];
                filter = lib.singleton {
                  action = "include";
                  keywords = [ "🇯🇵|JP|jp|日本|Japan" ];
                };
              })
            ])
            (lib.mkMerge [
              {
                tag = "Germany";
                type = "selector";
                outbounds = [ "Proteus-NixOS-2" ];
              }
              (lib.mkIf isSubscribeEnabled {
                outbounds = [ "{all}" ];
                filter = lib.singleton {
                  action = "include";
                  keywords = [ "🇩🇪|GE|ge|DE|de|德国|德|Germany|Deutschland" ];
                };
              })
            ])
            # (lib.mkMerge [
            #   {
            #     tag = "Others";
            #     type = "selector";
            #     outbounds = [
            #       # "Socks5"
            #     ];
            #   }
            #   (lib.mkIf isSubscribeEnabled {
            #     outbounds = [ "{all}" ];
            #     filter = lib.singleton {
            #       action = "exclude";
            #       keywords = [
            #         "🇭🇰|HK|hk|香港|港|HongKong|🇹🇼|TW|tw|台湾|臺灣|台|Taiwan|🇸🇬|SG|sg|新加坡|狮|Singapore|🇯🇵|JP|jp|日本|Japan|🇺🇸|US|us|美国|美|United States|🇬🇧|UK|uk|英国|英|United Kingdom|🇩🇪|GE|ge|DE|de|德国|德|Germany|Deutschland"
            #       ];
            #     };
            #   })
            # ])
          ];
        };
      };
    }).config.outbounds;
in
{
  dns.servers = lib.mkBefore (
    map (
      tag:
      dnsServerCfg.default
      // {
        inherit tag;
        detour = tag;
      }
    ) (map (outbound: outbound.tag) outbounds)
  );
  inherit outbounds;
}

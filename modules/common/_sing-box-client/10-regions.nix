{
  dnsServerCfg,
  lib,
  pkgs,
  ...
}:
let
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
            {
              tag = "HongKong";
              type = "selector";
              outbounds = [ "Proteus-NixOS-5" ];
            }
            {
              tag = "UnitedKingdom";
              type = "selector";
              outbounds = [ "Proteus-NixOS-4" ];
            }
            {
              tag = "UnitedStates";
              type = "selector";
              outbounds = [
                "Proteus-NixOS-0"
                "Proteus-NixOS-1"
                "Proteus-NixOS-2"
              ];
            }
            # {
            #   tag = "Taiwan";
            #   type = "selector";
            #   outbounds = [ ];
            # }
            # {
            #   tag = "Singapore";
            #   type = "selector";
            #   outbounds = [ ];
            # }
            # {
            #   tag = "Japan";
            #   type = "selector";
            #   outbounds = [ "Proteus-NixOS-3" ];
            # }
            {
              tag = "Germany";
              type = "selector";
              outbounds = [ "Block" ];
            }
            # {
            #   tag = "Others";
            #   type = "selector";
            #   outbounds = [
            #     # "Socks5"
            #   ];
            # }
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

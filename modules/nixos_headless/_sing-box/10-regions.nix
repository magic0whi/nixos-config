{ dnsServerCfg, lib, ... }:
let
  outbounds = [
    # {
    #   tag = "Germany";
    #   type = "selector";
    #   outbounds = [ ];
    # }
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
      outbounds = [ "Proteus-NixOS-0" ];
    }
    {
      tag = "Others";
      type = "selector";
      outbounds = [ "Socks5" ];
    }
  ];
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

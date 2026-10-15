{
  dnsServerCfg,
  lib,
  ...
}:
let
  pri = 0.11 * 2000;
  _outbounds = [
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
in
{
  dns.servers = lib.mkOrder pri (
    map (
      tag:
      dnsServerCfg.default
      // {
        inherit tag;
        detour = tag;
      }
    ) (map (outbound: outbound.tag) _outbounds)
  );
  outbounds = lib.mkOrder pri _outbounds;
}

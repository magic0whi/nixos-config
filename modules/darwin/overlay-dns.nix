{
  const,
  config,
  lib,
  machineConfigs,
  ...
}:
let
  ns_hostname = const.networking.findFirstHostBySubdomain "ns1";
  zone_names = lib.mapAttrsToList (_: zone: zone.name) machineConfigs.${ns_hostname}.config.services.bind.zones;
in
{
  # I mainly use EasyTier for overlay network, so I put networking.search setting here
  networking.search = [ const.domain ];
  # TIP:
  # - Flush DNS cache `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`
  # NOTE `doggo` and `dig` won't help debug this, use `scutil --dns` instead
  environment.etc = lib.mkMerge (
    map (zone_name: {
      "resolver/${zone_name}".text = lib.concatMapStringsSep "\n" (ip: "nameserver ${ip}") (
        let
          ns_host_nics = const.networking.allHostAddrs.${ns_hostname};
        in
        if config.services.easytier.enable then
          with ns_host_nics.easytier;
          [
            ipv4NoCidr
            ipv6NoCidr
          ]
        else
          with ns_host_nics.tailscale;
          [
            ipv4NoCidr
            ipv6NoCidr
          ]
      );
    }) zone_names
  );
}

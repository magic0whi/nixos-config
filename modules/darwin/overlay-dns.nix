{
  const,
  config,
  lib,
  machineConfigs,
  ...
}:
let
  ns_hostname = const.networking.findFirstHostBySubdomain "ns1";
in
{
  # I mainly use EasyTier for overlay network, so I put networking.search setting here
  networking.search = [ const.domain ];
  # TIP:
  # - Flush DNS cache `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`
  # NOTE `doggo` and `dig` won't help debug this, use `scutil --dns` instead
  environment.etc = lib.mkIf config.services.easytier.enable (
    lib.mkMerge (
      map (zone_name: {
        "resolver/${zone_name}".text = lib.concatMapStringsSep "\n" (ip: "nameserver ${ip}") (
          with const.networking.allHostAddrs.${ns_hostname}.easytier;
          [
            ipv4NoCidr
            ipv6NoCidr
          ]
        );
      }) (lib.mapAttrsToList (_: zone: zone.name) machineConfigs.${ns_hostname}.config.services.bind.zones)
    )
  );
}

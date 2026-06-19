{
  const,
  lib,
  machineConfigs,
  ...
}:
let
  ns_hostname = const.networking.findHost "ns1";
  iface = builtins.elemAt const.networking.hostAddrs.${ns_hostname} 1;
  zone_names = lib.mapAttrsToList (
    _: zone:
    if (lib.isDerivation zone.file) then lib.removeSuffix ".zone" zone.file.name else lib.removeSuffix ".zone" zone.file
  ) machineConfigs.${ns_hostname}.config.services.bind.zones;
in
{
  # I mainly use EasyTier for overlay network, so I put networking.search setting here
  networking.search = [ const.domain ];
  # TIP: Flush DNS cache `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`
  environment.etc = builtins.foldl' (
    acc: zone_name:
    acc
    // {
      "resolver/${zone_name}".text = lib.concatMapStringsSep "\n" (ip: "nameserver ${ip}") (
        lib.optional (iface ? ipv4) iface.ipv4 ++ lib.optional (iface ? ipv6) iface.ipv6
      );
    }
  ) { } zone_names;
}

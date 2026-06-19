{
  config,
  lib,
  machineConfigs,
  const,
  ...
}:
let
  nic_name = config.services.easytier.instances.main.extraSettings.flags.dev_name;
in
{
  networking.firewall = {
    extraInputRules = ''
      iifname "${nic_name}" ip daddr 100.100.100.101 accept
    '';
    allowedTCPPortRanges = [
      {
        from = 11010;
        to = 11013;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 11010;
        to = 11012;
      }
    ];
  };
  systemd.network.networks."50-easytier-dns" =
    let
      ns_hostname = const.networking.findHost "ns1";
    in
    {
      name = nic_name;
      networkConfig.KeepConfiguration = "yes";
      domains = [
        "${const.domain}" # Search Domain
      ]
      # Routing Domain for reverse zones
      ++ lib.remove "~${const.domain}" (
        lib.mapAttrsToList (
          _: zone:
          if (lib.isDerivation zone.file) then
            "~${lib.removeSuffix ".zone" zone.file.name}" # The '~' prefix makes this a routing domain
          else
            "~${lib.removeSuffix ".zone" zone.file}"
        ) machineConfigs.${ns_hostname}.config.services.bind.zones
      );
      dns =
        let
          iface = builtins.elemAt const.networking.hostAddrs.${ns_hostname} 1;
        in
        lib.optional (iface ? ipv4) "${iface.ipv4}#${const.domain}"
        ++ lib.optional (iface ? ipv6) "${iface.ipv6}#${const.domain}";
    };
}

{
  config,
  lib,
  machineConfigs,
  myvars,
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
      ns_hostname = myvars.networking.findHost "ns1";
    in
    {
      name = nic_name;
      networkConfig.KeepConfiguration = "yes";
      domains = [
        "${myvars.domain}" # Search Domain
      ]
      # Routing Domain for reverse zones
      ++ lib.remove "~${myvars.domain}" (
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
          iface = builtins.elemAt myvars.networking.hostAddrs.${ns_hostname} 1;
        in
        lib.optional (iface ? ipv4) "${iface.ipv4}#${myvars.domain}"
        ++ lib.optional (iface ? ipv6) "${iface.ipv6}#${myvars.domain}";
    };
}

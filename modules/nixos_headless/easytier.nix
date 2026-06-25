{
  config,
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
}

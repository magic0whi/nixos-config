{
  config,
  lib,
  const,
  pkgs,
  ...
}:
{
  services.resolved.settings.Resolve.DNSStubListenerExtra = [ const.networking.dockerIP ]; # for split DNS
  networking.firewall.extraInputRules = ''
    iifname { "docker0", "br-*" } ip daddr ${const.networking.dockerIP} meta l4proto { tcp, udp }
      th dport 53 accept comment "Docker containers to systemd-resolved"
  '';
  users.users.${const.username}.extraGroups = [ "docker" ];
  systemd.services.docker.path = lib.mkIf (config.virtualisation.docker.daemon.settings.firewall-backend == "nftables") [
    pkgs.nftables
  ];

  virtualisation.docker = {
    enable = true;
    # storageDriver = "btrfs"; # conflict with feature: containerd-snapshotter
    daemon.settings = {
      firewall-backend = "nftables"; # Requires >= docker 29
      # Enables pulling using containerd, which supports restarting from a partial pull.
      # Ref https://docs.docker.com/storage/containerd/
      features.containerd-snapshotter = true;
      dns = [ const.networking.dockerIP ]; # systemd-resolved for split DNS
    };
  };
}

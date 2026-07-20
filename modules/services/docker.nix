{
  config,
  lib,
  const,
  pkgs,
  ...
}:
let
  docker_cidr = "172.16.0.0-172.31.255.252";
in
{
  services.resolved.settings.Resolve.DNSStubListenerExtra = [ "172.17.0.1" ]; # for split DNS
  users.users.${const.username}.extraGroups = [ "docker" ];
  #  With auto_redirect enabled, sing-box allocates a dynamic local TCP port and installs several nft rules. Because
  # `redirect` rewrites the packet destination to the host, traffic finally enters the INPUT chain. But nixos-fw's
  # default-drop INPUT policy silently dropped these packets. Accepting 172.18.0.0/16 on INPUT covers all Docker bridge
  # subnets regardless of bridge name or port changes across restarts.
  networking.firewall.extraInputRules = lib.mkIf config.services.sing-box.enable ''
    ip saddr { ${docker_cidr} } accept comment "Allow Docker to reach auto_redirect ports"
  '';
  systemd.services.docker.path = lib.mkIf (config.virtualisation.docker.daemon.settings.firewall-backend == "nftables") [
    pkgs.nftables
  ];

  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_29.override {
      version = "29.5.2";
      cliRev = "v29.5.2";
      mobyRev = "docker-v29.5.2";

      cliHash = "sha256-kHgDZVr6mAyCtZ6bSG9FWV0GhWDfXLXzHYFrmjFzO9w=";
      mobyHash = "sha256-lux7tTyF6vm5wuIXs+z3Ygd2v4JjgHbRvOXNA4kjNtg=";
    };
    # storageDriver = "btrfs"; # conflict with feature: containerd-snapshotter
    daemon.settings = {
      firewall-backend = "nftables"; # Requires >= docker 29
      # Enables pulling using containerd, which supports restarting from a partial pull.
      # Ref https://docs.docker.com/storage/containerd/
      features.containerd-snapshotter = true;
      dns = [ "172.17.0.1" ]; # systemd-resolved for split DNS
    };
  };
}

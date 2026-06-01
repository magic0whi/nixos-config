{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
{
  users.users.${myvars.username}.extraGroups = [ "docker" ];
  # =============================================================================
  # Docker + sing-box auto_redirect & FakeIP Conflict Resolution
  # =============================================================================
  # Background:
  #   sing-box runs a TUN interface with `auto_redirect` (TProxy-like) and FakeIP (198.18.0.0/15) alongside Docker
  #   (172.18.0.0/16). A prior fix (repo:proxy_template/96146a7d) had disabled auto_redirect entirely to resolve a
  #   TProxy vs. Docker NAT conflict. The following config re-enables it correctly.
  #
  # Root Cause of the Original Conflict:
  #   sing-box's TProxy hooks prerouting at `dstnat - 1`, intercepting container traffic BEFORE Docker's POSTROUTING
  #   MASQUERADE NAT, breaking outbound container connectivity. Bypassing container IPs at routing level broke FakeIP,
  #   since fake IPs sent to the host kernel were dropped as unroutable.
  #
  # Fix 1: bypass chain:
  #   Inserted at `prerouting priority dstnat - 5` (ahead of sing-box's hook). Tags all container-sourced traffic with
  #   the sing-box bypass mark (ct mark 0x00002024), letting Docker's native NAT handle it normally.
  #
  #   Critical exception: traffic destined for FakeIP (198.18.0.0/15) hits a `return` BEFORE the bypass mark, so TProxy
  #   can still catch and resolve those connections.
  networking.nftables.tables = lib.mkIf config.services.sing-box.enable {
    sb_docker_fix = {
      family = "inet";
      content = ''
        chain docker-prerouting {
          type filter hook prerouting priority dstnat - 5; policy accept;

          # Do NOT bypass FakeIP traffic. Let sing-box handle it.
          ip daddr 198.18.0.0/15 return

          # Bypass everything else from Docker
          # Skip 172.19.0.1/30
          ip saddr { 172.16.0.0/15, 172.19.0.4-172.31.255.255 } ct mark set 0x00002024
        }
      '';
    };
  };
  # Fix 2: extraInputRules:
  #   With auto_redirect enabled, sing-box allocates a dynamic local TCP port
  #   and installs several nft rules. Because `redirect` rewrites the packet
  #   destination to the host, traffic finally enters the INPUT chain. But
  #   nixos-fw's default-drop INPUT policy silently dropped these packets.
  #   Accepting 172.18.0.0/16 on INPUT covers all Docker bridge subnets
  #   regardless of bridge name or port changes across restarts.
  # =============================================================================
  networking.firewall.extraInputRules = lib.mkIf config.services.sing-box.enable ''
    ip saddr { 172.16.0.0/15, 172.19.0.4-172.31.255.255 } accept comment "Allow Docker to reach auto_redirect ports"
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
    };
  };
}

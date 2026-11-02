{
  mylib,
  config,
  const,
  lib,
  pkgs,
  ...
}:
let
  hostname = config.networking.hostName;
in
{
  sops =
    let
      mkRestartUnits = lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
        restartUnits = map (name: "easytier-${name}.service") (builtins.attrNames config.services.easytier.instances);
      };
    in
    {
      secrets.easytier_network_secret = mkRestartUnits;
      templates."easytier.env" = lib.mkMerge [
        mkRestartUnits
        { content = mylib.toEnv { ET_NETWORK_SECRET = config.sops.placeholder.easytier_network_secret; }; }
      ];
    };
  services.easytier = {
    enable = true;
    allowSystemForward = true;
    instances.main = {
      environmentFiles = [ config.sops.templates."easytier.env".path ];
      settings = {
        network_name = const.domain;
        ipv4 = config.vars.hostAddrs.${hostname}.easytier.ipv4;
        inherit hostname;
        # peers = [ "txt://txt.easytier.cn" ];
        peers = map (i: "udp://proteus-nixos-${toString i}.${const.cloud_domain}") [
          0
          1
          2
          3
          4
          5
        ];
        listeners = [
          "tcp://0.0.0.0:11010"
          "udp://0.0.0.0:11010"
          "wg://0.0.0.0:11011"
          "quic://0.0.0.0:11012"
          "ws://0.0.0.0:11011/"
          "wss://0.0.0.0:11012/"
          "faketcp://0.0.0.0:11013"
        ];
      };
      extraSettings = {
        ipv6 = config.vars.hostAddrs.${config.networking.hostName}.easytier.ipv6;
        flags = lib.mkMerge [
          {
            accept_dns = true; # Enable Magic DNS
            # tld_dns_zone = const.domain; # Comment-out as it override my custom DNS route
            # Ref: https://easytier.cn/en/guide/network/host-public-server.html#disable-forwarding
            relay-network-whitelist = ""; # Disable forwarding for other networks
            relay_all_peer_rpc = true; # Help others hole punching
          }
          (lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) { dev_name = "et-main"; })
        ];
        stun_servers = [
          "stun.miwifi.com"
          "stun.chat.bilibili.com"
        ];
      };
    };
  };
}

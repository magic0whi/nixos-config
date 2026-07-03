{
  mylib,
  config,
  const,
  lib,
  pkgs,
  ...
}:
{
  sops =
    let
      mkRestartUnits = lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
        restartUnits = map (name: "easytier-${name}.service") (builtins.attrNames config.services.easytier.instances);
      };
      nodes = [
        0
        1
        2
        3
        4
        5
      ];
    in
    {
      secrets =
        let
          sopsFile = "${const.secretsDir}/common.sops.yaml";
        in
        lib.mkMerge (
          # Iterate mkMerge list
          map
            # add restartUnits optionally for each attrsets in the outer mkMerge list
            (builtins.mapAttrs (
              _: secret:
              lib.mkMerge [
                secret
                mkRestartUnits
              ]
            ))
            (
              map (secret: secret) (
                lib.singleton { easytier_network_secret = { inherit sopsFile; }; }
                ++ (map (i: { "easytier_peer_${toString i}" = { inherit sopsFile; }; }) nodes)
              )
            )
        );
      templates."easytier.env" = lib.mkMerge [
        mkRestartUnits
        {
          content = mylib.toEnv {
            ET_NETWORK_SECRET = config.sops.placeholder.easytier_network_secret;
            # ET_PEERS uses comma delimiter
            ET_PEERS = builtins.concatStringsSep "," (
              map (i: "udp://${config.sops.placeholder."easytier_peer_${toString i}"}") nodes
            );
          };
        }
      ];
    };
  services.easytier = {
    enable = true;
    allowSystemForward = true;
    instances.main = {
      environmentFiles = [ config.sops.templates."easytier.env".path ];
      settings = {
        network_name = const.domain;
        ipv4 = config.vars.hostAddrs.${config.networking.hostName}.easytier.ipv4;
        hostname = config.networking.hostName;
        # peers = [ "txt://txt.easytier.cn" ];
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
            relay_all_peer_rpc = true; # Help others hole punching
          }
          (lib.mkIf (!pkgs.stdenv.isDarwin) { dev_name = "et-main"; })
        ];
        stun_servers = [
          "stun.miwifi.com"
          "stun.chat.bilibili.com"
        ];
      };
    };
  };
}

{
  config,
  myvars,
  lib,
  pkgs,
  ...
}:
{
  sops =
    lib.mapAttrsRecursiveCond (attrs: !(attrs ? sopsFile || attrs ? content))
      (
        _: secret:
        lib.mkMerge [
          secret
          (lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
            restartUnits = map (name: "easytier-${name}.service") (builtins.attrNames config.services.easytier.instances);
          })
        ]
      )
      {
        secrets =
          let
            sopsFile = "${myvars.secretsDir}/common.sops.yaml";
          in
          {
            "easytier_network_secret" = { inherit sopsFile; };
            "easytier_peer_0" = { inherit sopsFile; };
            "easytier_peer_4" = { inherit sopsFile; };
            "easytier_peer_5" = { inherit sopsFile; };
          };
        templates."easytier.env" = {
          content = ''
            ET_NETWORK_SECRET=${config.sops.placeholder.easytier_network_secret}
            # ET_PEERS uses comma delimiter
            ET_PEERS=udp://${config.sops.placeholder.easytier_peer_0},udp://${config.sops.placeholder.easytier_peer_4},udp://${config.sops.placeholder.easytier_peer_5}
          '';
        };
      };
  services.easytier = {
    enable = true;
    allowSystemForward = true;
    instances.main = {
      environmentFiles = [ config.sops.templates."easytier.env".path ];
      settings = {
        network_name = myvars.domain;
        ipv4 = "${builtins.elemAt (map (i: i.ipv4) myvars.networking.hostAddrs.${config.networking.hostName}) 1}/24";
        hostname = config.networking.hostName;
        peers = [ "txt://txt.easytier.cn" ];
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
        ipv6 = "${builtins.elemAt (map (i: i.ipv6) myvars.networking.hostAddrs.${config.networking.hostName}) 1}/64";
        flags = lib.mkMerge [
          {
            accept_dns = true; # Enable Magic DNS
            # relay_all_peer_rpc = true; # Help others hole punching
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

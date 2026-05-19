{
  config,
  myvars,
  lib,
  pkgs,
  ...
}: {
  networking = lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
    firewall = {
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
  };
  sops = let
    restartUnits = map (name: "easytier-${name}.service") (builtins.attrNames config.services.easytier.instances);
    sopsFile = "${myvars.secrets_dir}/common.sops.yaml";
  in {
    secrets = {
      "easytier_network_secret" =
        {inherit sopsFile;}
        // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {inherit restartUnits;};
      "easytier_peer_0" =
        {inherit sopsFile;}
        // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {inherit restartUnits;};
    };
    templates."easytier.env" =
      {
        content = ''
          ET_NETWORK_SECRET=${config.sops.placeholder.easytier_network_secret}
          # ET_PEERS uses comma delimiter
          ET_PEERS=udp://${config.sops.placeholder.easytier_peer_0}
        '';
      }
      // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {inherit restartUnits;};
  };
  services.easytier = {
    enable = true;
    instances.main = {
      environmentFiles = [config.sops.templates."easytier.env".path];
      settings = {
        network_name = myvars.domain;
        ipv4 = "${builtins.elemAt (map (i: i.ipv4) myvars.networking.hosts_addr.${config.networking.hostName}) 1}/24";
        hostname = config.networking.hostName;
        peers = ["txt://txt.easytier.cn"];
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
        ipv6 = "${builtins.elemAt (map (i: i.ipv6) myvars.networking.hosts_addr.${config.networking.hostName}) 1}/64";
        flags =
          {
            accept_dns = true; # Enable Magic DNS
            # relay_all_peer_rpc = true; # Help others hole punching
          }
          // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {dev_name = "et-main";};
        stun_servers = ["stun.miwifi.com" "stun.chat.bilibili.com"];
      };
    };
  };
}

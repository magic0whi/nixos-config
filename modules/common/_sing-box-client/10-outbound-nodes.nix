{ config, lib, ... }:
let
  nodes =
    map
      (
        node:
        {
          # Shared config across nodes
          type = "naive";
          server_port = 443;
          username = "proteus";
          password._secret = config.sops.secrets.sb_nodes_anytls_password.path;
          tls = {
            enabled = true;
            server_name = "${node.tag}.proteus11451.online";
          };
          quic = true;
          udp_over_tcp = true;
        }
        // node
      )
      (
        map
          (num: {
            tag = "Proteus-NixOS-${num}";
            server._secret = config.sops.secrets."easytier_peer_${num}".path;
          })
          [
            "0"
            "1"
            "2"
            "3"
            "4"
            "5"
          ]
      )
  # ++ lib.singleton {
  #   tag = "Socks5";
  #   type = "socks";
  #   # detour = "";
  #   server = "127.0.0.1";
  #   server_port = 1080;
  #   username = "1111111111";
  #   password = "2222222222";
  #   udp_over_tcp = false;
  #   version = "5";
  # }
  ;
in
{
  outbounds = lib.mkMerge [
    (lib.mkBefore (
      lib.singleton {
        tag = "Auto";
        type = "urltest";
        # interval = "10m"; # default 3m
        # tolerance = 50; # default 50 ms
        # url = "http://www.gstatic.com/generate_204"; # default https://www.gstatic.com/generate_204
        outbounds = map (node: node.tag) nodes ++ lib.optional config.services.sing-box.subscribe.enable "{all}";
      }
    ))
    (lib.mkAfter nodes)
  ];
}

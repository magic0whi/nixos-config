{ config, lib, ... }:
let
  nodes =
    map
      (
        node:
        {
          server_port = 443;
          password._secret = config.sops.secrets.sb_nodes_anytls_password.path;
          tls = {
            enabled = true;
            reality = {
              enabled = true;
              public_key._secret = config.sops.secrets.sb_nodes_reality_pub_key.path;
              short_id._secret = config.sops.secrets.sb_nodes_reality_short_id.path;
            };
            server_name._secret = config.sops.secrets.sb_nodes_server_name.path;
            utls = {
              enabled = true;
              fingerprint = "chrome";
            };
          };
          type = "anytls";
        }
        // node
      )
      [
        # TODO: temporary disable
        # {
        #   tag = "Proteus-NixOS-0";
        #   server._secret = config.sops.secrets.easytier_peer_0.path;
        # }
        # {
        #   tag = "Proteus-NixOS-4";
        #   server._secret = config.sops.secrets.easytier_peer_4.path;
        # }
        # {
        #   tag = "Proteus-NixOS-5";
        #   server._secret = config.sops.secrets.easytier_peer_5.path;
        # }
      ]
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
        outbounds = map (node: node.tag) nodes ++ [ "{all}" ];
      }
    ))
    (lib.mkAfter nodes)
  ];
}

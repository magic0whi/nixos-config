{
  config,
  const,
  lib,
  pkgs,
  ...
}:
let
  nodes =
    map
      (
        node:
        (lib.evalModules {
          modules = lib.singleton {
            options.nodeCfg = lib.mkOption {
              type = with lib.types; submodule { freeformType = (pkgs.formats.json { }).type; };
              default = lib.mkMerge [
                node
                {
                  # Shared config across nodes
                  type = "naive";
                  server_port = 443;
                  username = "proteus";
                  password._secret = config.sops.secrets.sb_nodes_anytls_password.path;
                  tls.enabled = true;
                  # NOTE: China Mobile heavily throttles QUIC traffic
                  # quic = true;
                  udp_over_tcp = true;
                }
              ];
            };
          };
        }).config.nodeCfg
      )
      (
        map (
          i:
          let
            server = "${lib.toLower i}.${const.cloudDomain}";
          in
          {
            tag = i;
            inherit server;
            tls.server_name = server;
          }
        ) const.networking.cloudNodes
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
    (lib.mkOrder (0.1 * 2000) (
      lib.singleton {
        tag = "Auto";
        type = "urltest";
        # interval = "10m"; # default 3m
        # tolerance = 50; # default 50 ms
        # url = "http://www.gstatic.com/generate_204"; # default https://www.gstatic.com/generate_204
        outbounds = map (node: node.tag) nodes;
      }
    ))
    (lib.mkOrder 0 nodes)
  ];
}

{
  config,
  lib,
  mylib,
  myvars,
  pkgs,
  ...
}:
{
  sops.secrets =
    let
      sopsFile = "${myvars.secretsDir}/common.sops.yaml";
    in
    builtins.mapAttrs
      (
        _: secret:
        lib.mkMerge [
          secret
          ((lib.optionalAttrs (!pkgs.stdenv.isDarwin)) { restartUnits = [ "sing-box.service" ]; })
        ]
      )
      {
        # "sb_client_linux.json" = {
        #   sopsFile = "${myvars.secretsDir}/sb_client_linux.json.sops";
        #   format = "binary";
        #   restartUnits = [ "sing-box.service" ];
        # };
        sb_nodes_anytls_password = { inherit sopsFile; };
        sb_nodes_reality_short_id = { inherit sopsFile; };
        sb_nodes_reality_pub_key = { inherit sopsFile; };
        sb_nodes_server_name = { inherit sopsFile; };
        sb_nodes_Proteus-NixOS-0 = { inherit sopsFile; };
        sb_nodes_Proteus-NixOS-4 = { inherit sopsFile; };
        sb_nodes_Proteus-NixOS-5 = { inherit sopsFile; };
        sb_ts_auth_key = { inherit sopsFile; };
      };
  services.sing-box = {
    enable = true;
    settings = import ./_sing-box-client {
      inherit
        config
        lib
        mylib
        myvars
        pkgs
        ;
      isDarwin = true;
      isLinux = false;
    };
  };
}

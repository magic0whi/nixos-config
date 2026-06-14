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
      restartUnits = [ "sing-box.service" ];
    in
    {
      # "sb_client_linux.json" = {
      #   sopsFile = "${myvars.secretsDir}/sb_client_linux.json.sops";
      #   format = "binary";
      #   restartUnits = [ "sing-box.service" ];
      # };
      sb_nodes_password = { inherit sopsFile restartUnits; };
      sb_nodes_public_key = { inherit sopsFile restartUnits; };
      sb_nodes_short_id = { inherit sopsFile restartUnits; };
      sb_nodes_server_name = { inherit sopsFile restartUnits; };
      sb_nodes_Proteus-NixOS-0 = { inherit sopsFile restartUnits; };
      sb_nodes_Proteus-NixOS-4 = { inherit sopsFile restartUnits; };
      sb_nodes_Proteus-NixOS-5 = { inherit sopsFile restartUnits; };
      sb_ts_auth_key = { inherit sopsFile restartUnits; };
    };
  networking.firewall.trustedInterfaces = [ "sing0" ];
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

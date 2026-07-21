{
  config,
  lib,
  mylib,
  const,
  pkgs,
  ...
}:
{
  sops.secrets =
    let
      sopsFile = "${const.secretsDir}/common.sops.yaml";
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
        "sb_test.json" = {
          sopsFile = "${const.secretsDir}/sb_test.json.sops";
          format = "binary";
        };
        sb_nodes_anytls_password = { inherit sopsFile; };
        sb_nodes_reality_short_id = { inherit sopsFile; };
        sb_nodes_reality_pub_key = { inherit sopsFile; };
        sb_nodes_server_name = { inherit sopsFile; };
        sb_ts_auth_key = { inherit sopsFile; };
        sb_subscribe_url = { inherit sopsFile; };
      };

  services = lib.mkMerge [
    {
      sing-box.subscribe = {
        # enable = true;
        settings = {
          subscribes = lib.singleton {
            User-Agent = "ClashMetaForAndroid/2.11.20.Meta";
            emoji = 1;
            enabled = true;
            prefix = "";
            subgroup = "";
            tag = "tag_1";
            url._secret = config.sops.secrets."sb_subscribe_url".path;
          };
          auto_set_outbounds_dns = {
            proxy = "";
            direct = "";
          };
          save_config_path = "./config.json";
          auto_backup = false;
          exclude_protocol = "ssr";
          config_template = "";
          Only-nodes = false;
        };
      };
    }
    {
      sing-box = {
        enable = true;
        package = pkgs.sing-box-beta;
        # Full config.json encryption, to ease the debugging
        settings = {
          _secret = config.sops.secrets."sb_test.json".path;
          quote = false;
        };

        # settings = import ./_sing-box-client {
        #   inherit
        #     config
        #     lib
        #     mylib
        #     const
        #     pkgs
        #     ;
        # };
      };
    }
    (lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
      networkd-dispatcher = {
        enable = true;
        rules = {
          restart-sing-box = {
            onState = [ "routable" ];
            # Ref: https://manpages.debian.org/testing/networkd-dispatcher/networkd-dispatcher.8.en.html
            script = ''
              # shellcheck disable=SC2154
              if [[ $IFACE == "${
                config.vars.hostAddrs.${config.networking.hostName}.wire.name
              }" && $AdministrativeState == "configured" ]]; then
                echo "Restarting Tor ..."
                systemctl restart tor
              fi
              exit 0
            '';
          };
        };
      };
    })
  ];
}

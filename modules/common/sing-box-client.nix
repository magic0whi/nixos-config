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
    # Add conditional restartUnits to the secrets
    builtins.mapAttrs
      (
        _: secretCfg:
        lib.mkMerge [
          secretCfg
          ((lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin)) { restartUnits = [ "sing-box.service" ]; })
        ]
      )
      {
        "sb_test.json" = {
          sopsFile = "${const.secretsDir}/sb_test.json.sops";
          format = "binary";
        };
        sb_nodes_anytls_password = { inherit sopsFile; };
      };

  services = lib.mkMerge [
    {
      sing-box = {
        enable = true;
        # Full config.json encryption, to ease the debugging
        # settings = {
        #   _secret = config.sops.secrets."sb_test.json".path;
        #   quote = false;
        # };

        settings = import ./_sing-box-client {
          inherit
            config
            lib
            mylib
            const
            pkgs
            ;
        };
      };
    }
    (lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
      networkd-dispatcher = {
        enable = true;
        rules.restart-sing-box = {
          onState = [ "routable" ];
          # Ref: https://manpages.debian.org/testing/networkd-dispatcher/networkd-dispatcher.8.en.html
          script = ''
            # shellcheck disable=SC2154
            if [[ $IFACE == "${
              config.vars.hostAddrs.${config.networking.hostName}.wire.name
            }" && $AdministrativeState == "configured" ]]; then
              echo "Restarting sing-box ..."
              systemctl restart sing-box.service
            fi
            exit 0
          '';
        };
      };
    })
  ];
}

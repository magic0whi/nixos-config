{
  mySecrets,
  config,
  lib,
  mylib,
  const,
  pkgs,
  ...
}:
let
  not_darwin = !pkgs.stdenv.hostPlatform.isDarwin;
in
{
  sops.secrets =
    # Add conditional restartUnits to the secrets
    builtins.mapAttrs
      (
        _: secretCfg:
        lib.mkMerge [
          secretCfg
          ((lib.optionalAttrs not_darwin) { restartUnits = [ "sing-box.service" ]; })
        ]
      )
      {
        # "sing-box_config.json" = {
        #   sopsFile = "${mySecrets + "/sing-box_config.json.sops"}";
        #   format = "binary";
        # };
        sing-box_anytls_password.sopsFile = mySecrets + "/services/sing-box.sops.yaml";
      };

  services = lib.mkMerge [
    {
      sing-box = {
        enable = true;
        # Full config.json encryption, to ease the debugging
        # settings = {
        #   _secret = config.sops.secrets."sing-box_config.json".path;
        #   quote = false;
        # };

        settings = import ./_sing-box-client {
          inherit
            config
            lib
            mylib
            const
            mySecrets
            pkgs
            ;
        };
      };
    }
    (lib.optionalAttrs not_darwin {
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

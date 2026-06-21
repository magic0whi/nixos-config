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
        # "sb_test.json" = {
        #   sopsFile = "${const.secretsDir}/sb_test.json.sops";
        #   format = "binary";
        # };
        sb_nodes_anytls_password = { inherit sopsFile; };
        sb_nodes_reality_short_id = { inherit sopsFile; };
        sb_nodes_reality_pub_key = { inherit sopsFile; };
        sb_nodes_server_name = { inherit sopsFile; };
        sb_nodes_Proteus-NixOS-0 = { inherit sopsFile; };
        sb_nodes_Proteus-NixOS-4 = { inherit sopsFile; };
        sb_nodes_Proteus-NixOS-5 = { inherit sopsFile; };
        sb_ts_auth_key = { inherit sopsFile; };
        sb_subscribe_url = { inherit sopsFile; };
      };
  systemd.services.sing-box.serviceConfig.ExecStartPre = lib.mkAfter (
    lib.singleton (
      let
        sing-box-subscribe = pkgs.fetchFromGitHub {
          owner = "Toperlock";
          repo = "sing-box-subscribe";
          rev = "9b94f3e61d1a14e6eca228df189ada8719ca9174";
          hash = "sha256-MvjoAL4wZxIR37B08ViPcdvXN+OFwn+TV1qf2Boe4Nw=";
        };
        providerSettings = {
          Only-nodes = false;
          auto_backup = false;
          auto_set_outbounds_dns = {
            direct = "";
            proxy = "";
          };
          config_template = "";
          exclude_protocol = "ssr";
          save_config_path = "./config.json";
          subscribes = [
            {
              User-Agent = "ClashMetaForAndroid/2.11.20.Meta";
              emoji = 1;
              enabled = true;
              prefix = "";
              subgroup = "";
              tag = "tag_1";
              url._secret = config.sops.secrets."sb_subscribe_url".path;
            }
          ];
        };
        python = lib.getExe (
          pkgs.python3.withPackages (
            ps: with ps; [
              requests
              paramiko
              scp
              chardet
              flask
              pyyaml
              ruamel-yaml
            ]
          )
        );
      in
      pkgs.writeShellScript "sing-box-subscribe" ''
        WORK_DIR="$STATE_DIRECTORY/sing-box-subscribe"
        [ ! -d "$WORK_DIR" ] && mkdir "$WORK_DIR"
        cp -r ${sing-box-subscribe}/* "$WORK_DIR"
        chmod -R +w "$WORK_DIR"

        cp "$RUNTIME_DIRECTORY/config.json" "$STATE_DIRECTORY/sing-box-subscribe/config_template/0config.json"

        ${(import "${pkgs.path}/nixos/lib/utils.nix" { inherit config lib pkgs; }).genJqSecretsReplacementSnippet
          providerSettings
          "/var/lib/sing-box/sing-box-subscribe/providers.json" # NOTE genJqSecretsReplacementSnippet use single quotes on path
        }

        cd "$STATE_DIRECTORY/sing-box-subscribe"
        ${python} main.py --template_index 0
        cp config.json "$RUNTIME_DIRECTORY/config.json"
      ''
    )
  );
  services.sing-box = {
    enable = true;
    package = pkgs.sing-box-beta;
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

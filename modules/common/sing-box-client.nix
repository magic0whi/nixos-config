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
        sb_ts_auth_key = { inherit sopsFile; };
        sb_subscribe_url = { inherit sopsFile; };
      };
  systemd.services.sing-box.serviceConfig.ExecStartPre = lib.mkAfter (
    lib.singleton (
      let
        update_interval = 60 * 60 * 24 * 7; # Update interval in seconds
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
              ruamel-yaml
              chardet
              pyyaml
              flask
            ]
          )
        );
      in
      pkgs.writeShellScript "sing-box-subscribe" ''
        PATH="${pkgs.gawk}/bin":$PATH
        CACHE_DIR="$STATE_DIRECTORY/sing-box-subscribe"
        CURRENT_HASH=$(sha256sum "$RUNTIME_DIRECTORY/config.json" | awk '{print $1}')
        CURRENT_TIME=$(date +%s)

        # Trigger update if template changed, time interval exceeded, or cache is missing
        if [ "$CURRENT_HASH" != "$(cat "$CACHE_DIR/last_hash" 2>/dev/null || echo "")" ] \
          || [ $((CURRENT_TIME - $(cat "$CACHE_DIR/last_time" 2>/dev/null || echo "0"))) -ge ${toString update_interval} ] \
          || [ ! -f "$CACHE_DIR/config.json" ]
        then
          work_dir="$RUNTIME_DIRECTORY/sing-box-subscribe"

          echo "Updating sing-box subscription..."
          mkdir "$work_dir"
          cp -r ${sing-box-subscribe}/* "$work_dir"
          chmod -R +w "$work_dir"

          cp "$RUNTIME_DIRECTORY/config.json" "$work_dir/config_template/0config.json"

          ${(import "${pkgs.path}/nixos/lib/utils.nix" { inherit config lib pkgs; }).genJqSecretsReplacementSnippet
            providerSettings
            "/run/sing-box/sing-box-subscribe/providers.json" # NOTE genJqSecretsReplacementSnippet use single quotes on path
          }

          cd "$work_dir"
          ${python} main.py --template_index 0
          cp config.json "$CACHE_DIR/"
          echo "$CURRENT_HASH" > "$CACHE_DIR/last_hash"
          echo "$CURRENT_TIME" > "$CACHE_DIR/last_time"
        else
          echo "Template unchanged and interval not reached. Using cached config."
        fi
        cp "$CACHE_DIR/config.json" "$RUNTIME_DIRECTORY/config.json"
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

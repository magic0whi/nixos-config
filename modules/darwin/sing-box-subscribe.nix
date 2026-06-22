{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.sing-box.subscribe;
in
{
  config = lib.mkIf cfg.enable {
    debug =
      let
        cfg = config.services.sing-box.subscribe;
      in
      pkgs.writeShellScript "sing-box-subscribe" ''
        set -euo pipefail
        PATH="${pkgs.gawk}/bin":$PATH
        RUNTIME_DIRECTORY="/var/run/sing-box"
        STATE_DIRECTORY="${config.launchd.daemons.sing-box.serviceConfig.WorkingDirectory}";

        CACHE_DIR="$STATE_DIRECTORY/sing-box-subscribe"
        CURRENT_HASH=$(sha256sum "$RUNTIME_DIRECTORY/config.json" | awk '{print $1}')
        CURRENT_TIME=$(date +%s)

        [ ! -d "$CACHE_DIR" ] && mkdir "$CACHE_DIR"

        # Trigger update if template changed, time interval exceeded, or cache is missing
        if [ "$CURRENT_HASH" != "$(cat "$CACHE_DIR/last_hash" 2>/dev/null || echo "")" ] \
          || [ $((CURRENT_TIME - $(cat "$CACHE_DIR/last_time" 2>/dev/null || echo "0"))) -ge ${toString cfg.updateInterval} ] \
          || [ ! -f "$CACHE_DIR/config.json" ]
        then
          work_dir="$RUNTIME_DIRECTORY/sing-box-subscribe"

          echo "Updating sing-box subscription..."
          mkdir -p "$work_dir"
          cp -r ${cfg.src}/* "$work_dir"
          chmod -R +w "$work_dir"

          cp "$RUNTIME_DIRECTORY/config.json" "$work_dir/config_template/0config.json"

          ${
            (import "${pkgs.path}/nixos/lib/utils.nix" {
              inherit lib pkgs;
              config = { };
            }).genJqSecretsReplacementSnippet
            cfg.settings
            # NOTE genJqSecretsReplacementSnippet use single quotes on path, fixed on fork, PR in progress
            # "/run/sing-box/sing-box-subscribe/providers.json"
            "$work_dir/providers.json"
          }

          cd "$work_dir"
          ${lib.getExe cfg.pythonEnv} main.py --template_index 0
          cp config.json "$CACHE_DIR/"
          echo "$CURRENT_HASH" > "$CACHE_DIR/last_hash"
          echo "$CURRENT_TIME" > "$CACHE_DIR/last_time"
        else
          echo "Template unchanged and interval not reached. Using cached config."
        fi
        cp "$CACHE_DIR/config.json" "$RUNTIME_DIRECTORY/config.json"
      '';
    launchd.daemons.sing-box.script = toString config.debug;
  };
}

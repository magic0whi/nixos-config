{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.trafficQuota;
  script = pkgs.writeShellScript "check-traffic-quota" ''
    set -euo pipefail

    CURRENT_YEAR=$(date +%Y)
    CURRENT_MONTH=$(date +%-m)

    # Query vnstat for total RX + TX for the current month.
    # We include all interfaces, but exclude lo, docker, br-, veth, tailscale, virbr
    # Or more robustly, we can just sum up the interfaces matched by "^(eth|en|wl|venet)".
    # This correctly catches enp46s0, eth0, ens3, wlo1, etc.
    TOTAL_BYTES=$(vnstat --json | jq -r --arg year "$CURRENT_YEAR" --arg month "$CURRENT_MONTH" '
      [
        .interfaces[] |
        select(.name | test("^(eth|en|wl|venet)")) |
        .traffic.month[]? |
        select(.date.year == ($year|tonumber) and .date.month == ($month|tonumber)) |
        .rx + .tx
      ] | add // 0
    ')

    LIMIT=$((${toString cfg.limit} * 1024**3)) # The threshold in bytes

    if [ "$TOTAL_BYTES" -ge "$LIMIT" ]; then
      echo "Traffic quota exceeded: $TOTAL_BYTES bytes >= $LIMIT bytes. Shutting down."
      systemctl poweroff
    else
      echo "Current traffic: $TOTAL_BYTES bytes. Limit: $LIMIT bytes."
    fi
  '';
in
{
  options.services.trafficQuota = {
    enable = lib.mkEnableOption "traffic quota checker";
    limit = lib.mkOption {
      type = lib.types.int;
      default = 196;
      description = "Traffic quota limit in GiB";
    };
  };
  config = lib.mkIf cfg.enable {
    services.vnstat.enable = true;
    systemd.services.traffic-quota = {
      description = "Check vnstat traffic quota and shutdown if exceeded";
      after = [ "vnstat.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = script;
      };
      path = with pkgs; [
        jq
        vnstat
        vnstat
        systemd
      ];
    };
    systemd.timers.traffic-quota = {
      description = "Timer for traffic quota checker";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "5m";
      };
    };
  };
}

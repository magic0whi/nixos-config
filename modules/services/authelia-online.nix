{ const, pkgs, ... }:
{
  # To use it, add `authelia-online.service` to a unit's `wants` and `after`
  systemd.services.authelia-online = {
    description = "Wait for Authelia (auth.${const.domain}) to be online";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    # No `RemainAfterExit`, so the check re-runs every time a consumer starts.
    # Disable the start limit: a consumer restart loop must not rate-limit this check.
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig.Type = "oneshot";
    script = ''
      echo "Waiting for Authelia (auth.${const.domain}) to be ready..."
      until ${pkgs.curl}/bin/curl -sSf \
        "https://auth.${const.domain}/.well-known/openid-configuration" >/dev/null; do
        sleep 2
      done
      echo "Authelia is online."
    '';
  };
}

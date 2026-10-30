{
  config,
  const,
  lib,
  pkgs,
  ...
}:
let
  runtimeDir = "/var/run/niks3-auto-upload";
in
{
  services.niks3-auto-upload.authTokenFile = "${runtimeDir}/niks3-oidc-token";
  launchd.daemons.niks3-auto-upload.serviceConfig.ProgramArguments = lib.mkBefore [
    "${pkgs.writeShellScript "fetch-authelia-token" ''
      set -euo pipefail

      echo "Fetching fresh token from Authelia via client_credentials..." >&2

      RESPONSE=$("${pkgs.curl}/bin/curl" -s -X POST "https://auth.${const.domain}/api/oidc/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -u "niks3_yajuusexnpai:$(cat ${config.sops.secrets.niks3_client_secret_yajuusexnpai.path})" \
        -d "grant_type=client_credentials" \
        -d "audience=niks3") # Explicitly request the audience, otherwise you will get `"aud": []`

      umask 077
      mkdir -p ${runtimeDir}
      echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.access_token // empty' > ${config.services.niks3-auto-upload.authTokenFile}

      exec "$@"
    ''}"
  ];
}

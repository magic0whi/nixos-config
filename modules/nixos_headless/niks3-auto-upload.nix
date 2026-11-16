{
  config,
  const,
  pkgs,
  ...
}:
{
  services.niks3-auto-upload.authTokenFile =
    # config.sops.secrets.niks3-auto-upload_api_token.path;
    "\${RUNTIME_DIRECTORY}/niks3-oidc-token";
  systemd.services.niks3-auto-upload.serviceConfig = {
    RuntimeDirectory = "niks3-auto-upload";
    RuntimeDirectoryMode = "0700";
    ExecStartPre = [
      "+${pkgs.writeShellScript "fetch-authelia-token" ''
        set -euo pipefail

        echo "Fetching fresh token from Authelia via client_credentials..." >&2

        RESPONSE="$(${pkgs.curl}/bin/curl -fsX POST \
          -H 'Content-Type: application/x-www-form-urlencoded' \
          -u "niks3:$(<${config.sops.secrets.niks3_client_secret.path})" \
          -d 'grant_type=client_credentials' \
          -d 'scope=authelia.bearer.authz' \
          -d 'audience=niks3' \
          'https://auth.${const.domain}/api/oidc/token')"

        printf '%s' "$RESPONSE" | ${pkgs.jq}/bin/jq -er '.access_token' > $RUNTIME_DIRECTORY/niks3-oidc-token

        echo "Bearer token retrieve successfully." >&2

        chown --reference=$RUNTIME_DIRECTORY $RUNTIME_DIRECTORY/niks3-oidc-token
      ''}"
    ];
  };
}

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

        RESPONSE=$("${pkgs.curl}/bin/curl" -s -X POST "https://auth.${const.domain}/api/oidc/token" \
          -H "Content-Type: application/x-www-form-urlencoded" \
          -u "niks3_yajuusexnpai:$(cat ${config.sops.secrets.niks3_client_secret_yajuusexnpai.path})" \
          -d "grant_type=client_credentials" \
          -d "audience=niks3") # Explicitly request the audience, otherwise you will get `"aud": []`

        echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.access_token // empty' > $RUNTIME_DIRECTORY/niks3-oidc-token
        chown --reference=$RUNTIME_DIRECTORY $RUNTIME_DIRECTORY/niks3-oidc-token
      ''}"
    ];
  };
}

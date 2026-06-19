{
  config,
  lib,
  const,
  pkgs,
  ...
}:
{
  sops.secrets.niks3_client_secret_yajuusexnpai.sopsFile = "${const.secretsDir}/common.sops.yaml";
  services.niks3-auto-upload = {
    enable = true;
    serverUrl = "https://niks3.${const.domain}";
    # authTokenFile = config.sops.secrets.niks3-auto-upload_api_token.path;
    authTokenFile = "\${RUNTIME_DIRECTORY}/niks3-oidc-token";
  };
  systemd.services.niks3-auto-upload.serviceConfig = {
    RuntimeDirectory = "niks3-auto-upload";
    RuntimeDirectoryMode = "0700";
    ExecStartPre = [
      "+${pkgs.writeShellScript "fetch-authelia-token" ''
        set -eufo pipefail

        echo "Fetching fresh token from Authelia via client_credentials..." >&2

        RESPONSE=$(${lib.getExe pkgs.curl} -s -X POST "https://auth.${const.domain}/api/oidc/token" \
          -H "Content-Type: application/x-www-form-urlencoded" \
          -u "niks3_yajuusexnpai:$(cat ${config.sops.secrets.niks3_client_secret_yajuusexnpai.path})" \
          -d "grant_type=client_credentials" \
          -d "audience=niks3") # Explicitly request the audience, otherwise you will get `"aud": []`

        echo "$RESPONSE" | ${lib.getExe pkgs.jq} -r '.access_token // empty' > $RUNTIME_DIRECTORY/niks3-oidc-token
        chown --reference=$RUNTIME_DIRECTORY $RUNTIME_DIRECTORY/niks3-oidc-token
      ''}"
    ];
  };
}

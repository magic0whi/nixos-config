{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
{
  sops.secrets = {
    # niks3-auto-upload_api_token = {
    #   key = "niks3_api_token";
    #   sopsFile = "${myvars.secretsDir}/common.sops.yaml";
    #   # niks3-auto-upload.service is triggered by socket so not need restart
    # };
    niks3_client_secret_yajuusexnpai.sopsFile = "${myvars.secretsDir}/common.sops.yaml";
  };
  services.niks3-auto-upload = {
    enable = true;
    serverUrl = "https://niks3.${myvars.domain}";
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

        RESPONSE=$(${lib.getExe pkgs.curl} -s -X POST "https://auth.${myvars.domain}/api/oidc/token" \
          -H "Content-Type: application/x-www-form-urlencoded" \
          -u "niks3_yajuusexnpai:$(cat ${config.sops.secrets.niks3_client_secret_yajuusexnpai.path})" \
          -d "grant_type=client_credentials" \
          -d "audience=niks3") # Explicitly request the audience, otherwise you will get `"aud": []`

        TOKEN=$(echo "$RESPONSE" | ${lib.getExe pkgs.jq} -r '.access_token // empty')

        echo "$TOKEN" > $RUNTIME_DIRECTORY/niks3-oidc-token
        chown --reference=$RUNTIME_DIRECTORY $RUNTIME_DIRECTORY/niks3-oidc-token
      ''}"
    ];
  };
}

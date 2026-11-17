{
  config,
  const,
  lib,
  mypkg,
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

        ${lib.getExe mypkg.fetch-authelia-token} \
          --client-id niks3 \
          --client-secret-file ${lib.escapeShellArg config.sops.secrets.niks3_client_secret.path} \
          --audience niks3 \
          --auth-url ${lib.escapeShellArg "https://auth.${const.domain}"} \
          > "$RUNTIME_DIRECTORY/niks3-oidc-token"

        chown --reference=$RUNTIME_DIRECTORY $RUNTIME_DIRECTORY/niks3-oidc-token
      ''}"
    ];
  };
}

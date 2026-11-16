{
  config,
  const,
  lib,
  mypkg,
  pkgs,
  ...
}:
let
  runtimeDir = "/var/run/niks3-auto-upload";
in
{
  services.niks3-auto-upload.authTokenFile = "${runtimeDir}/niks3-oidc-token";
  launchd.daemons.niks3-auto-upload.serviceConfig = {
    # launchd doesn't passes NIX_SSL_CERT_FILE to the daemon, without this nixpkgs curl fails TLS with exit 60
    # Ref: https://nix.dev/manual/nix/2.18/installation/env-variables#nix_ssl_cert_file
    EnvironmentVariables.NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    ProgramArguments = lib.mkBefore [
      "${pkgs.writeShellScript "fetch-authelia-token" ''
        set -euo pipefail

        umask 077
        mkdir -p ${runtimeDir}

        ${lib.getExe mypkg.fetch-authelia-token} \
          --client-id niks3 \
          --client-secret-file ${lib.escapeShellArg config.sops.secrets.niks3_client_secret.path} \
          --audience niks3 \
          --domain ${lib.escapeShellArg const.domain} \
          > ${lib.escapeShellArg config.services.niks3-auto-upload.authTokenFile}

        exec "$@"
      ''}"
    ];
  };
}

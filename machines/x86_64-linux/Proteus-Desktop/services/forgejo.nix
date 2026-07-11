{
  config,
  lib,
  const,
  pkgs,
  ...
}:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "git" ];
        AAAA = [ "git" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  sops =
    let
      sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
    in
    {
      secrets = {
        forgejo_db_password = {
          inherit sopsFile;
          restartUnits = [ "forgejo.service" ];
          # owner = config.services.forgejo.user;
        };
        forgejo_authelia_secret = {
          inherit sopsFile;
          restartUnits = [ "forgejo.service" ];
          owner = config.services.forgejo.user;
        };
      };
    };
  services.forgejo = {
    enable = true;
    group = "storage";
    database = {
      type = "postgres";
      # socket = "/run/postgresql"; # The module will prefer UNIX Domain Socket if this is not null
      createDatabase = false; # Must be disabled if using remote DB
      host = "postgresql.${const.domain}";
      passwordFile = config.sops.secrets.forgejo_db_password.path;
    };
    lfs.enable = true;
    settings = {
      server = {
        DOMAIN = "git.${const.domain}";
        ROOT_URL = "https://git.${const.domain}/";
        HTTP_ADDR = "127.0.0.1";
        # PROTOCOL = "http+unix"; # HTTP through UNIX Domain Socket
      };
      openid.ENABLE_OPENID_SIGNIN = false; # Only allow OAuth
      oauth2_client = {
        ENABLE_AUTO_REGISTRATION = true;
        ACCOUNT_LINKING = "auto";
        USERNAME = "userid";
      };
      # Delegating registration entirely to Authelia
      service.ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
      # Add support for actions, based on act: https://github.com/nektos/act
      actions = {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "github";
      };
    };
    dump = {
      enable = true;
      backupDir = "${const.storagePath}/Backups/forgejo";
      interval = const.backupTimes.forgejo;
      type = "tar.zst";
    };
  };
  systemd.services = lib.mkMerge [
    # Wait for LDAP Online
    {
      forgejo = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        preStart = lib.mkBefore ''
          set -euo pipefail

          echo "Waiting for LDAP (ldap.${const.domain}) to be ready..."
          while ! ${lib.getExe pkgs.netcat} -z ldap.proteus.eu.org 636; do
            sleep 2
          done
          echo "LDAP is online, proceeding with Forgejo startup."
        '';
      };
    }
    # Add OIDC
    {
      forgejo = {
        preStart = ''
          set -euo pipefail

          mkdir -p ${config.services.forgejo.stateDir}/custom/public/assets/img/auth/
          cp -f ${pkgs.authelia.src}/docs/static/images/branding/logo.png ${config.services.forgejo.stateDir}/custom/public/assets/img/auth/authelia.png
        '';
        postStart = ''
          set -euo pipefail

          # Wait for Forgejo to be fully ready to accept CLI commands
          while [ "$(${lib.getExe pkgs.curl} -sSf https://git.${const.domain}/api/healthz | ${lib.getExe pkgs.jq} -r '.status')" != "pass" ]; do
            sleep 1
          done

          # Read the secret from your age file
          OIDC_SECRET=$(cat ${config.sops.secrets.forgejo_authelia_secret.path})

          # The environment variables (FORGEJO_WORK_DIR, etc.) are already injected by systemd.
          # `forgejo` is injected in `systemd.services.forgejo.path`
          FORGEJO_CLI="forgejo --config ${config.services.forgejo.stateDir}/custom/conf/app.ini admin auth"

          # Check if the Authelia auth source already exists
          if ! $FORGEJO_CLI list | grep -q "Authelia"; then
            echo "Adding Authelia OIDC provider..."
            $FORGEJO_CLI add-oauth \
              --name Authelia \
              --provider openidConnect \
              --key "forgejo" \
              --secret "$OIDC_SECRET" \
              --auto-discover-url "https://auth.${const.domain}/.well-known/openid-configuration" \
              --icon-url "/assets/img/auth/authelia.png"
          else
            echo "Updating existing Authelia OIDC provider..."
            AUTHELIA_ID=$($FORGEJO_CLI list | ${lib.getExe pkgs.gawk} '/Authelia/ {print $1;}')
            $FORGEJO_CLI update-oauth \
              --name Authelia \
              --id $AUTHELIA_ID \
              --provider openidConnect \
              --key "forgejo" \
              --secret "$OIDC_SECRET" \
              --auto-discover-url "https://auth.${const.domain}/.well-known/openid-configuration" \
              --icon-url "/assets/img/auth/authelia.png"
          fi
        '';
      };
    }
  ];

  services.traefik.dynamicConfigOptions.http = {
    routers.forgejo = {
      rule = "Host(`git.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "forgejo";
      tls = { };
    };
    services.forgejo.loadBalancer = {
      servers = [ { url = "http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}"; } ];
      healthCheck.path = "/api/healthz";
    };
  };
}

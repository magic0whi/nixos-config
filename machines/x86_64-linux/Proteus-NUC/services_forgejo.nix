{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
let
  restart_runner_units = map (name: "gitea-runner-${name}.service") (
    builtins.attrNames config.services.gitea-actions-runner.instances
  );
  clean_runner_units = map (s: lib.removeSuffix ".service" s) restart_runner_units;
in
{
  sops =
    let
      sopsFile = "${myvars.secrets_dir}/${config.networking.hostName}.sops.yaml";
    in
    lib.mkMerge [
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
      }
      {
        # Generate the runner token for the global runner
        # `sudo -u forgejo nix run nixpkgs#forgejo -- forgejo-cli --config /var/lib/forgejo/custom/conf/app.ini actions generate-runner-token`
        # Note this is different with `nixpgs#forgejo-cli`.
        # The token will not change until regenerate it. To regenerate the token, go through WebUI -> Site
        # administration -> Actions -> Runners, click the edit and check the "Regenerate token" box, them save
        secrets.forgejo_runner_token = {
          inherit sopsFile;
          restartUnits = restart_runner_units;
        };
        templates."forgejo_runner_token.env" = {
          restartUnits = restart_runner_units;
          content = "TOKEN=${config.sops.placeholder.forgejo_runner_token}";
          # The module uses DynamicUser
          # owner = config.systemd.services."gitea-runner-${builtins.head (builtins.attrNames config.services.gitea-actions-runner.instances)}".serviceConfig.User;
        };
      }
    ];
  services.forgejo = {
    enable = true;
    database = {
      type = "postgres"; # Module will automatically provision PostgreSQL
      # Prefer UNIX Domain Socket if this is not null
      socket = "/run/postgresql";
      passwordFile = config.sops.secrets.forgejo_db_password.path;
    };
    lfs.enable = true;
    settings = {
      server = {
        DOMAIN = "git.${myvars.domain}";
        ROOT_URL = "https://git.${myvars.domain}/";
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
      interval = myvars.backup_times.forgejo;
      type = "tar.zst";
    };
  };
  systemd.services = lib.mkMerge [
    {
      forgejo = {
        preStart = ''
          set -eufo pipefail

          mkdir -p ${config.services.forgejo.stateDir}/custom/public/assets/img/auth/
          cp -f ${pkgs.authelia.src}/docs/static/images/branding/logo.png ${config.services.forgejo.stateDir}/custom/public/assets/img/auth/authelia.png
        '';
        postStart = ''
          set -eufo pipefail

          # Wait for Forgejo to be fully ready to accept CLI commands
          while [ "$(${lib.getExe pkgs.curl} -sSf https://git.${myvars.domain}/api/healthz | ${lib.getExe pkgs.jq} -r '.status')" != "pass" ]; do
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
              --auto-discover-url "https://auth.${myvars.domain}/.well-known/openid-configuration" \
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
              --auto-discover-url "https://auth.${myvars.domain}/.well-known/openid-configuration" \
              --icon-url "/assets/img/auth/authelia.png"
          fi
        '';
      };
    }
    (lib.genAttrs clean_runner_units (_: {
      serviceConfig.ExecStartPre = lib.mkAfter [
        (pkgs.writeShellScript "wait-for-forgejo" ''
          set -eufo pipefail

          echo "Waiting for Forgejo to be online..."
          # Retry until Forgejo reports status=pass
          while [ "$(${lib.getExe pkgs.curl} -sSf https://git.${myvars.domain}/api/healthz | ${lib.getExe pkgs.jq} -r '.status')" != "pass" ]; do
            sleep 1
          done

          echo "Forgejo is online, proceeding with runner startup."
        '')
      ];
    }))
  ];

  services.traefik.dynamicConfigOptions.http = {
    routers.forgejo = {
      rule = "Host(`git.${myvars.domain}`)";
      entryPoints = [ "websecure" ];
      service = "forgejo";
      tls = { };
    };
    services.forgejo.loadBalancer = {
      servers = [
        { url = "http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}"; }
      ];
      healthCheck.path = "/api/healthz";
    };
  };

  # Local Action Runner connecting to your Forgejo instance
  # Docker is required to execute Docker-based action labels
  services.gitea-actions-runner =
    let
      default_instance = {
        enable = true;
        name = "${config.networking.hostName}-runner";
        url = "https://git.${myvars.domain}";
        tokenFile = config.sops.templates."forgejo_runner_token.env".path;
        labels = [
          "debian-latest:docker://node:20-bookworm"
          # Fake the ubuntu name, because node provides no ubuntu builds
          "ubuntu-latest:docker://node:20-bookworm"
          # "ubuntu-24.04-arm:docker://node:20-bookworm"
        ];
        # https://gitea.com/gitea/act_runner/src/commit/40dcee0991c3bd33b657bb77aa1f2f46d69cc0e2/internal/pkg/config/config.example.yaml
        settings = {
          # The nodejs still couldn't recognize my self-signed cert
          runner.capacity = 3; # Set to your desired number of simultaneous jobs
          runner.envs.NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
          container = {
            options = "-v ${config.security.pki.caBundle}:/etc/ssl/certs/ca-certificates.crt:ro";
            valid_volumes = [ config.security.pki.caBundle ];
            force_pull = false;
          };
        };
      };
    in
    {
      package = pkgs.forgejo-runner;
      instances = {
        x86_64 = default_instance;
        # arm64 = lib.recursiveUpdate default_instance {
        #   name = "${config.networking.hostName}-runner-arm64";
        #   labels = ["ubuntu-24.04-arm:docker://node:20-bookworm"];
        #   settings = {
        #     runner.capacity = 1;
        #     container.options = default_instance.settings.container.options + " --platform=linux/arm64";
        #     force_pull = false;
        #   };
        # };
        # riscv64 = lib.recursiveUpdate default_instance {
        #   name = "${config.networking.hostName}-runner-riscv64";
        #   labels = ["ubuntu-24.04-riscv64:docker://custom-node-riscv64:22.22.0"];
        #   settings = {
        #     runner.capacity = 1;
        #     container.options = default_instance.settings.container.options + " --platform=linux/riscv64";
        #     force_pull = false;
        #   };
        # };
      };
    };
}

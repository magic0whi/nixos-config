{
  config,
  lib,
  const,
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
      sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
    in
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
    };

  systemd.services = lib.genAttrs clean_runner_units (_: {

    serviceConfig = {
      SupplementaryGroups = [ "kvm" ];
      ExecStartPre = lib.mkAfter [
        # Wait for LDAP Online
        (pkgs.writeShellScript "wait-for-forgejo" ''
          set -euo pipefail

          echo "Waiting for Forgejo to be online..."
          # Retry until Forgejo reports status=pass
          while [ "$(${lib.getExe pkgs.curl} -sSf https://git.${const.domain}/api/healthz | ${lib.getExe pkgs.jq} -r '.status')" != "pass" ]; do
            sleep 1
          done

          echo "Forgejo is online, proceeding with runner startup."
        '')
      ];
    };
  });

  # Local Action Runner connecting to Forgejo instance
  # Docker is required to execute Docker-based action labels
  services.gitea-actions-runner =
    let
      default_instance = {
        enable = true;
        name = "${config.networking.hostName}-runner";
        url = "https://git.${const.domain}";
        tokenFile = config.sops.templates."forgejo_runner_token.env".path;
        labels = [
          # "debian-latest:docker://node:20-bookworm"
          # Fake the ubuntu name, because node provides no ubuntu builds
          "ubuntu-latest:docker://catthehacker/ubuntu:runner-latest"
          # "ubuntu-24.04-arm:docker://node:20-bookworm"
        ];
        # https://gitea.com/gitea/act_runner/src/commit/40dcee0991c3bd33b657bb77aa1f2f46d69cc0e2/internal/pkg/config/config.example.yaml
        settings = {
          # The nodejs still couldn't recognize my self-signed cert
          runner.capacity = 3; # Set to your desired number of simultaneous jobs
          runner.envs.NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
          container = {
            options = builtins.concatStringsSep " " [
              "-v ${config.security.pki.caBundle}:/etc/ssl/certs/ca-certificates.crt:ro"
              "--security-opt seccomp=unconfined"
              "--device=/dev/kvm"
            ];
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

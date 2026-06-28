# - To initialize the repository (one-time): restic-<Hostname> init
# - To check backup status: restic-<Hostname> snapshots
# - To retrieve latest snapshots:
#   restic-<Hostname> latest --target /tmp/restic-restore
#   restic-<Hostname> <Snapshot ID> --target /tmp/restic-restore
{
  config,
  machineConfigs,
  const,
  mylib,
  lib,
  ...
}:
let
  machine_cfg_s3 = machineConfigs.${const.networking.findFirstHostBySubdomain "s3"}.config;
  hostname = config.networking.hostName;
in
{
  services.prometheus.exporters.restic = {
    enable = true;
    repository = "s3:s3.${const.domain}/backups/${hostname}";
    passwordFile = config.sops.secrets.restic_password.path;
    user = config.sops.secrets.restic_password.owner;
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.prometheus-exporter-restic = {
      rule = "Host(`restic-${hostname}.exporter.${const.domain}`)";
      entryPoints = [ "websecure" ];
      middlewares = [ "authelia-auth" ];
      service = "prometheus-exporter-restic";
      tls = { };
    };
    services.prometheus-exporter-restic.loadBalancer.servers = lib.singleton {
      url = "http://127.0.0.1:${toString config.services.prometheus.exporters.restic.port}";
    };
  };

  sops =
    let
      sopsFile = "${const.secretsDir}/${hostname}.sops.yaml";
      restartUnits = [ "restic-backups-${hostname}.service" ];
      owner = config.services.restic.backups.${hostname}.user;
    in
    {
      # Restic repository encryption password
      secrets = {
        restic_password = {
          inherit sopsFile restartUnits owner;
        };
        restic_aws_access_key = { inherit sopsFile restartUnits; };
        restic_aws_secret_key = { inherit sopsFile restartUnits; };
      };
      templates."restic.env" = {
        inherit restartUnits owner;
        content = mylib.toEnv {
          AWS_ACCESS_KEY_ID = config.sops.placeholder.restic_aws_access_key;
          AWS_SECRET_ACCESS_KEY = config.sops.placeholder.restic_aws_secret_key;
        };
      };
    };
  services.restic.backups =
    let
      shared = {
        user = const.username; # Default root, set to primary user to ease the use of `restic-<Hostname>` command
        initialize = true; # Create the repository if it doesn’t exist
        passwordFile = config.sops.secrets.restic_password.path; # Password for restic backup itself
        # An environment file for your storage provider credentials (e.g., AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
        environmentFile = config.sops.templates."restic.env".path;

        # Retention policy
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
          "--keep-yearly 75"
        ];
        checkOpts = [ "--with-cache" ]; # Reuse existing cache
        # Run backup + prune + check weekly (Sundays at 3 AM)
        timerConfig = {
          OnCalendar = "*-*-* 03:00:00";
          # RandomizedDelaySec = "30m"; # Jitter
          Persistent = true; # Run immediately if system was off at scheduled time
        };
        # Performance tuning
        extraBackupArgs = [ "--limit-upload ${toString (50 * 1024)}" ];
        # Limit upload speed to 50 MB/s, unit is KiB/s
        extraOptions = [
          "s3.region=${machine_cfg_s3.services.garage.settings.s3_api.s3_region}"
          "read-concurrency=4" # Read concurrency for better throughput on ZFS
        ];
        # Paths to exclude from backup
        exclude = [
          "**/.Trash"
          "**/node_modules"
          # Cache directories
          "*/.cache"
          "*/cache"
        ];
      };
    in
    {
      ${hostname} = shared // {
        # Repository location on Proteus-Desktop
        repository = "s3:s3.${const.domain}/backups/${hostname}";
        # Paths to backup
        paths = [
          config.services.paperless.exporter.directory # Paperless
          config.services.postgresqlBackup.location # Postgresql
          config.services.forgejo.dump.backupDir # Forgejo
          # "/var/lib/tailscale"
        ];
      };
      "${hostname}_immich" = shared // {
        repository = "s3:s3.${const.domain}/backups/${hostname}_immich";
        paths = [ config.services.immich.mediaLocation ];
        pruneOpts = [ "--keep-last 1" ];
        exclude = shared.exclude ++ [
          # Temporary / runtime data
          "/srv/immich/upload/thumbs" # Regeneratable thumbnails
          "/srv/immich/upload/encoded-video" # Regeneratable transcodes
        ];
      };
    };
  systemd.tmpfiles.settings = {
    "01-acl-srv-immich-backups-default".${config.services.immich.mediaLocation}."A+".argument = "d:g:storage:rX";
    "01-acl-srv-immich-backups".${config.services.immich.mediaLocation}.A.argument = "g:storage:rX";
  };
}

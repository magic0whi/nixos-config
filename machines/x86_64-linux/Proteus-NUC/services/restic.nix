# - To initialize the repository (one-time): restic-<Hostname> init
# - To check backup status: restic-<Hostname> snapshots
# - To retrieve latest snapshots:
#   restic-<Hostname> latest --target /tmp/restic-restore
#   restic-<Hostname> <Snapshot ID> --target /tmp/restic-restore
# TODO: Proteus-Desktop need a postgresql backup
{
  config,
  machineConfigs,
  const,
  mylib,
  lib,
  ...
}:
let
  hostname_s3 = "Proteus-Desktop";
  hostname_s3_gcp = "Proteus-NixOS-3";
  machine_cfg_s3 = machineConfigs.${hostname_s3}.config;
  machine_cfg_s3_gcp = machineConfigs.${hostname_s3_gcp}.config;
  hostname = config.networking.hostName;
in
{
  sops =
    let
      sopsFile = "${const.secretsDir}/${hostname}.sops.yaml";
      restartUnits = [ "prometheus-restic-exporter.service" ];
      owner = config.services.restic.backups.main.user;
    in
    {
      # Restic repository encryption password
      secrets = {
        restic_password = {
          inherit sopsFile restartUnits owner;
        };
        restic_s3_access_key = { inherit sopsFile restartUnits; };
        restic_s3_secret_key = { inherit sopsFile restartUnits; };
        restic_gcp_s3_access_key = { inherit sopsFile restartUnits; };
        restic_gcp_s3_secret_key = { inherit sopsFile restartUnits; };
      };
      templates."restic_main.env" = {
        inherit restartUnits owner;
        content = mylib.toEnv {
          AWS_ACCESS_KEY_ID = config.sops.placeholder.restic_s3_access_key;
          AWS_SECRET_ACCESS_KEY = config.sops.placeholder.restic_s3_secret_key;
        };
      };
      templates."restic_gcp.env" = {
        inherit restartUnits owner;
        content = mylib.toEnv {
          AWS_ACCESS_KEY_ID = config.sops.placeholder.restic_gcp_s3_access_key;
          AWS_SECRET_ACCESS_KEY = config.sops.placeholder.restic_gcp_s3_secret_key;
        };
      };
    };

  vars.hostAddrs.${hostname} =
    let
      subdomains = {
        A = [ "restic-${hostname}.exporter" ];
        AAAA = [ "restic-${hostname}.exporter" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };

  # Currenly only export main backup metrics
  services.prometheus.exporters.restic = {
    enable = true;
    inherit (config.services.restic.backups.main) repository;
    environmentFile = config.sops.templates."restic_main.env".path;
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

  services.restic.backups =
    let
      shared = {
        user = const.username; # Default root, set to primary user to ease the use of `restic-<Hostname>` command
        initialize = true; # Create the repository if it doesn’t exist
        passwordFile = config.sops.secrets.restic_password.path; # Password for restic backup itself
        # An environment file for your storage provider credentials (e.g., AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
        environmentFile = lib.mkDefault config.sops.templates."restic_main.env".path;

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
        extraOptions = [ "read-concurrency=4" ]; # Read concurrency for better throughput on ZFS
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
      main = lib.mkMerge [
        shared
        {
          repository = "s3:${hostname_s3}.s3.${const.domain}/backups/${hostname}";
          extraOptions = [ "s3.region=${machine_cfg_s3.services.garage.settings.s3_api.s3_region}" ];
          # Paths to backup
          paths = [
            config.services.paperless.exporter.directory # Paperless
            # config.services.postgresqlBackup.location # Postgresql
            # config.services.forgejo.dump.backupDir # Forgejo
            # "/var/lib/tailscale"
          ];
        }
      ];
      gcp = lib.mkMerge [
        shared
        {
          repository = "s3:${hostname_s3_gcp}.s3.${const.domain}:8443/backups/${hostname}";
          environmentFile = config.sops.templates."restic_gcp.env".path;
          extraOptions = [ "s3.region=${machine_cfg_s3_gcp.services.garage.settings.s3_api.s3_region}" ];
          # Paths to backup
          paths = [
            config.services.paperless.exporter.directory # Paperless
            # config.services.postgresqlBackup.location # Postgresql
            # config.services.forgejo.dump.backupDir # Forgejo
            # "/var/lib/tailscale"
          ];
        }
      ];
      immich = lib.mkMerge [
        shared
        {
          repository = "s3:${hostname_s3}.s3.${const.domain}/backups/${hostname}_immich";
          extraOptions = [ "s3.region=${machine_cfg_s3.services.garage.settings.s3_api.s3_region}" ];
          pruneOpts = [ "--keep-last 1" ];
          paths = [ config.services.immich.mediaLocation ];
          exclude = shared.exclude ++ [
            # Temporary / runtime data
            "/srv/immich/upload/thumbs" # Regeneratable thumbnails
            "/srv/immich/upload/encoded-video" # Regeneratable transcodes
          ];
        }
      ];
    };
  systemd.tmpfiles.settings = {
    "01-acl-srv-immich-backups-default".${config.services.immich.mediaLocation}."A+".argument = "d:g:storage:rX";
    "01-acl-srv-immich-backups".${config.services.immich.mediaLocation}.A.argument = "g:storage:rX";
  };
}

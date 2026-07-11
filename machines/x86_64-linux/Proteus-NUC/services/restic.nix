{
  config,
  machineConfigs,
  const,
  mylib,
  lib,
  ...
}:
let
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
      secrets = {
        restic_s3_gcp_access_key = { inherit sopsFile restartUnits; };
        restic_s3_gcp_secret_key = { inherit sopsFile restartUnits; };
      };
      templates."restic_gcp.env" = {
        inherit restartUnits owner;
        content = mylib.toEnv {
          AWS_ACCESS_KEY_ID = config.sops.placeholder.restic_s3_gcp_access_key;
          AWS_SECRET_ACCESS_KEY = config.sops.placeholder.restic_s3_gcp_secret_key;
        };
      };
    };

  services.restic.backups =
    let
      hostname_s3_main = "Proteus-Desktop";
      machine_cfg_s3_main = machineConfigs.${hostname_s3_main}.config;

      hostname_s3_gcp = "Proteus-NixOS-3";
      machine_cfg_s3_gcp = machineConfigs.${hostname_s3_gcp}.config;

      shared = const.mkResticBackupsCfg config;
    in
    {
      main = {
        repository = "s3:${hostname_s3_main}.s3.${const.domain}/backups/${hostname}";
        extraOptions = [ "s3.region=${machine_cfg_s3_main.services.garage.settings.s3_api.s3_region}" ];
        # Paths to backup
        paths = [
          config.services.paperless.exporter.directory # Paperless
          # "/var/lib/tailscale"
        ];
      };
      gcp = lib.mkMerge [
        shared
        {
          repository = "s3:${hostname_s3_gcp}.s3.${const.domain}:8443/backups/${hostname}";
          environmentFile = config.sops.templates."restic_gcp.env".path;
          extraOptions = [ "s3.region=${machine_cfg_s3_gcp.services.garage.settings.s3_api.s3_region}" ];
          timerConfig = {
            OnCalendar = "Mon 03:00";
            # RandomizedDelaySec = "30m"; # Jitter
            Persistent = false; # Run immediately if system was off at scheduled time
          };
          # Paths to backup
          paths = [
            config.services.paperless.exporter.directory # Paperless
            # "/var/lib/tailscale"
          ];
        }
      ];
      immich = lib.mkMerge [
        shared
        {
          repository = "s3:${hostname_s3_main}.s3.${const.domain}/backups/${hostname}_immich";
          extraOptions = [ "s3.region=${machine_cfg_s3_main.services.garage.settings.s3_api.s3_region}" ];
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

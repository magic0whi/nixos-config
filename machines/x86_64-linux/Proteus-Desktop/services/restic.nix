{
  config,
  machineConfigs,
  const,
  mylib,
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
      # Restic repository encryption password
      secrets = {
        restic_password = { inherit sopsFile restartUnits owner; };
        restic_s3_main_access_key = { inherit sopsFile restartUnits; };
        restic_s3_main_secret_key = { inherit sopsFile restartUnits; };
      };
      templates."restic_main.env" = {
        inherit restartUnits owner;
        content = mylib.toEnv {
          AWS_ACCESS_KEY_ID = config.sops.placeholder.restic_s3_main_access_key;
          AWS_SECRET_ACCESS_KEY = config.sops.placeholder.restic_s3_main_secret_key;
        };
      };
    };

  services.restic.backups.main =
    let
      hostname_s3_main = "Proteus-NixOS-1";
      machine_cfg_s3_main = machineConfigs.${hostname_s3_main}.config;
    in
    {
      repository = "s3:${hostname_s3_main}.s3.${const.domain}:8443/backups/${hostname}";
      extraOptions = [ "s3.region=${machine_cfg_s3_main.services.garage.settings.s3_api.s3_region}" ];
      timerConfig = {
        OnCalendar = "Mon 03:00";
        # RandomizedDelaySec = "30m"; # Jitter
        Persistent = false; # Run immediately if system was off at scheduled time
      };
      paths = [
        config.services.postgresqlBackup.location # Postgresql
        config.services.forgejo.dump.backupDir # Forgejo
      ];
    };
}

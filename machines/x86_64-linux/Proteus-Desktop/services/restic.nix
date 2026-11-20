# TODO: remote garage hang after long connection
{
  config,
  machineConfigs,
  const,
  ...
}:
let
  hostname = config.networking.hostName;
in
{
  services.restic.backups.main =
    let
      hostname_s3_main = "Proteus-NixOS-1";
      machine_cfg_s3_main = machineConfigs.${hostname_s3_main}.config;
    in
    {
      repository = "s3:${hostname_s3_main}.s3.${const.domain}:8443/backups/${hostname}";
      extraOptions = [ "s3.region=${machine_cfg_s3_main.services.garage.settings.s3_api.s3_region}" ];
      timerConfig = {
        OnCalendar = "*-*-02 03:00";
        # RandomizedDelaySec = "30m"; # Jitter
        Persistent = false; # Run immediately if system was off at scheduled time
      };
      paths = [
        config.services.postgresqlBackup.location # Postgresql
        config.services.forgejo.dump.backupDir # Forgejo
      ];
    };
}

{
  config,
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

  services.restic.backups.main = const.mkResticBackupsCfg config;
}

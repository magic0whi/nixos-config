{
  config,
  lib,
  myvars,
  ...
}: {
  sops = let
    sopsFile = "${myvars.secrets_dir}/${config.networking.hostName}.sops.yaml";
    restartUnits = ["immich-machine-learning.service" "immich-server.service"];
  in {
    secrets = {
      immich_db_password = {inherit sopsFile restartUnits;};
      immich_oauth_secret = {
        inherit sopsFile restartUnits;
        owner = config.services.immich.user;
      };
    };
    templates."immich.env" = {
      inherit restartUnits;
      # content = "DB_PASSWORD=${config.sops.placeholder.immich_db_password}";
      # Immich don't use env DB_PASSWORD when using unix socket to connect the DB
      content = "DB_URL=postgresql://${config.services.immich.database.user}:${config.sops.placeholder.immich_db_password}@/${config.services.immich.database.user}";
    };
  };
  systemd.tmpfiles.settings.immich.${config.services.immich.mediaLocation}.e.mode = lib.mkForce "0750";
  services.immich = {
    enable = true;
    group = "storage";
    host = "127.0.0.1";
    # database.host = "postgresql.${myvars.domain}"; # Default: "/run/postgresql"
    secretsFile = config.sops.templates."immich.env".path;
    mediaLocation = "/srv/immich";
    # Ref: https://immich.proteus.eu.org/admin/system-settings?isOpen=authentication -> Export as JSON
    settings = {
      server.externalDomain = "https://immich.${myvars.domain}";
      oauth = {
        enabled = true;
        issuerUrl = "https://auth.${myvars.domain}";
        clientId = "immich";
        # NixOS will dynamically inject the contents of this file at runtime through `utils.genJqSecretsReplacement`
        clientSecret._secret = config.sops.secrets.immich_oauth_secret.path;
        autoLaunch = true;
      };
    };
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.immich = {
      rule = "Host(`immich.${myvars.domain}`)";
      entryPoints = ["websecure"];
      service = "immich";
      tls = {};
    };
    services.immich.loadBalancer = {
      servers = [{url = "http://127.0.0.1:${toString config.services.immich.port}";}];
      healthCheck.path = "/api/server/ping";
    };
  };
}

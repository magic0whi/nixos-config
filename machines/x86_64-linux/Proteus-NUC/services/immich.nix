{
  config,
  lib,
  const,
  mylib,
  ...
}:
let
  hostname = config.networking.hostName;
  hostname_psql = const.networking.findFirstHostBySubdomain "psql";

  use_unix_socket = hostname == hostname_psql;
in
{
  vars.hostAddrs.${hostname} =
    let
      subdomains = {
        A = [ "immich" ];
        AAAA = [ "immich" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };

  sops =
    let
      sopsFile = "${const.secretsDir}/${hostname}.sops.yaml";
      restartUnits = [
        "immich-machine-learning.service"
        "immich-server.service"
      ];
    in
    {
      secrets = {
        immich_db_password = { inherit sopsFile restartUnits; };
        immich_oauth_secret = {
          inherit sopsFile restartUnits;
          owner = config.services.immich.user;
        };
      };
      templates."immich.env" = {
        inherit restartUnits;
        # NOTE: Immich don't use env DB_PASSWORD when using unix socket to connect the DB
        content = mylib.toEnv (
          if use_unix_socket then
            { DB_URL = "postgresql://immich:${config.sops.placeholder.immich_db_password}@/immich"; }
          else
            { DB_PASSWORD = config.sops.placeholder.immich_db_password; }
        );
      };
    };
  systemd.tmpfiles.settings.immich.${config.services.immich.mediaLocation}.e.mode = lib.mkForce "0750";
  services.immich = {
    enable = true;
    group = "storage";
    host = "127.0.0.1";
    # Unix socket if psql is on the same machines
    database.host = if use_unix_socket then "/run/postgresql" else "psql.${const.domain}";
    secretsFile = config.sops.templates."immich.env".path;
    mediaLocation = "/srv/immich";
    # Ref: https://immich.proteus.eu.org/admin/system-settings?isOpen=authentication -> Export as JSON
    settings = {
      server.externalDomain = "https://immich.${const.domain}";
      oauth = {
        enabled = true;
        issuerUrl = "https://auth.${const.domain}";
        clientId = "immich";
        # NixOS will dynamically inject the contents of this file at runtime through `utils.genJqSecretsReplacement`
        clientSecret._secret = config.sops.secrets.immich_oauth_secret.path;
        autoLaunch = true;
      };
    };
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.immich = {
      rule = "Host(`immich.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "immich";
      tls = { };
    };
    services.immich.loadBalancer = {
      servers = [ { url = "http://127.0.0.1:${toString config.services.immich.port}"; } ];
      healthCheck.path = "/api/server/ping";
    };
  };
}

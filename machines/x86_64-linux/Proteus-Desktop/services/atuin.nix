{
  config,
  const,
  mylib,
  lib,
  pkgs,
  ...
}:
let
  hostname = config.networking.hostName;
  hostname_psql = const.networking.findFirstHostBySubdomain "psql";
in
{
  vars.hostAddrs.${hostname} =
    let
      subdomains = {
        A = [ "atuin" ];
        AAAA = [ "atuin" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };

  sops =
    let
      restartUnits = [ "atuin.service" ];
    in
    {
      secrets.atuin_db_password = {
        inherit restartUnits;
        sopsFile = "${const.secretsDir}/${hostname}.sops.yaml";
      };
      templates."atuin.env" = {
        inherit restartUnits;
        # If using unix socket, Atuin doesn't allow empty host, add a bogus host "114514"
        content = mylib.toEnv (
          if hostname == hostname_psql then
            { ATUIN_DB_URI = "postgres://atuin:${config.sops.placeholder.atuin_db_password}@114514/?host=/run/postgresql"; }
          else
            {
              ATUIN_DB_URI = "postgres://atuin:${config.sops.placeholder.atuin_db_password}@psql.${const.domain}/atuin?sslmode=require";
            }
        );
      };
    };

  services.atuin = {
    enable = true;
    port = 8889; # default 8888
    environmentFile = config.sops.templates."atuin.env".path;
    openRegistration = true;
  };

  systemd.services.atuin.serviceConfig.ExecStartPre = pkgs.writeShellScript "wait-for-ldap" ''
    set -euo pipefail

    echo "Waiting for LDAP (ldap.${const.domain}) to be ready..."
    while ! ${lib.getExe pkgs.netcat} -z ldap.proteus.eu.org 636; do
      sleep 2
    done
    echo "LDAP is online, proceeding with Atuin startup."
  '';

  services.traefik.dynamicConfigOptions.http = {
    routers.atuin = {
      rule = "Host(`atuin.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "atuin";
      tls = { };
    };
    services.atuin.loadBalancer = {
      servers = [ { url = "http://127.0.0.1:${toString config.services.atuin.port}"; } ];
      healthCheck.path = "/healthz";
    };
  };
}

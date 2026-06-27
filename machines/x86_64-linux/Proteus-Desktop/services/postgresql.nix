## TIP: To restore a clean backup:
# 1. psql "host=postgresql.proteus.eu.org port=5432 user=postgres dbname=postgres sslmode=require" -t -A -c "
#   SELECT 'DROP DATABASE IF EXISTS ' || quote_ident(datname) || ';'
#   FROM pg_database
#   WHERE NOT datistemplate AND datname NOT IN ('postgres', 'template1');
#   "
#   Manually drop then
# 2. psql "host=postgresql.proteus.eu.org port=5432 user=postgres dbname=postgres sslmode=require" -c "
#   DO \$\$
#   DECLARE
#       role record;
#   BEGIN
#       FOR role IN SELECT rolname FROM pg_roles WHERE NOT rolsuper AND rolname NOT LIKE 'pg_%' AND rolname != 'postgres' LOOP
#           EXECUTE 'DROP ROLE IF EXISTS ' || quote_ident(role.rolname);
#       END LOOP;
#   END \$\$;"
# 3. zstd -d -c /srv/Backups/psql/all.prev.sql.zstd | psql "host=postgresql.proteus.eu.org port=5432 user=postgres dbname=postgres sslmode=require" 2> restore_errors.log
{
  config,
  lib,
  machineConfigs,
  const,
  # nixpkgs-postgresql,
  pkgs,
  ...
}:
let
  backup_location = "${const.storagePath}/psql";
  machine_cfg = {
    authelia = machineConfigs.${const.networking.findFirstHostBySubdomain "auth"}.config;
    paperless = machineConfigs.${const.networking.findFirstHostBySubdomain "paperless"}.config;
    immich = machineConfigs.${const.networking.findFirstHostBySubdomain "immich"}.config;
  };
in
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "postgresql" ];
        AAAA = [ "postgresql" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  networking.firewall.allowedTCPPorts = [ config.services.postgresql.settings.port ];
  sops.secrets =
    let
      restartUnits = [
        "postgresql-setup.service"
        "postgresql.service"
      ];
    in
    {
      "postgresql_server.priv.pem" = {
        inherit restartUnits;
        sopsFile = "${const.secretsDir}/proteus_server.priv.pem.sops";
        format = "binary";
        owner = config.systemd.services.postgresql.serviceConfig.User;
      };
      postgres_ldap_bind_pw = {
        inherit restartUnits;
        sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
      };
    };
  # Ref: https://github.com/NixOS/nixpkgs/blob/549bd84d6279f9852cae6225e372cc67fb91a4c1/nixos/modules/services/databases/postgresql.nix#L684
  sops.templates."pg_hba_auth.conf" =
    let
      base_dn = "dc=" + builtins.replaceStrings [ "." ] [ ",dc=" ] const.domain;
    in
    {
      content =
        let
          ldap_opts = builtins.concatStringsSep " " [
            ''ldapurl="ldaps://ldap.${const.domain}/${base_dn}?uid?sub"''
            ''ldapbinddn="uid=${config.systemd.services.postgresql.serviceConfig.User},ou=ServiceAccounts,${base_dn}"''
            ''ldapbindpasswd="${config.sops.placeholder.postgres_ldap_bind_pw}"''
          ];
        in
        ''
          # type database DBuser auth-method [auth-options]
          # The ?sub part tells the server to perform a "subtree" search. It will traverse down into both `ou=People` and
          # `ou=ServiceAccounts` to find the matching uid
          host all all 0.0.0.0/0 ldap ${ldap_opts}
          host all all ::/0 ldap ${ldap_opts}

          # default value of `services.postgresql.authentication`
          local all postgres peer map=postgres
          # Catch-all
          local all all ldap ${ldap_opts}
          #local all all peer
        '';
      owner = config.systemd.services.postgresql.serviceConfig.User;
      restartUnits = [
        "postgresql-setup.service"
        "postgresql.service"
      ];
    };
  # TODO: Learn SQL
  services.postgresql = {
    enable = true;
    # package = nixpkgs-postgresql.legacyPackages.${
    #   pkgs.stdenv.hostPlatform.system
    # }.postgresql.override {ldapSupport = true;};
    package = pkgs.postgresql_17.override { ldapSupport = true; };
    enableJIT = true;
    enableTCPIP = true;
    settings = {
      ssl = true;
      ssl_min_protocol_version = "TLSv1.3";
      ssl_cert_file = "${const.secretsDir}/proteus_server.pub.pem";
      ssl_key_file = config.sops.secrets."postgresql_server.priv.pem".path;
      hba_file = lib.mkForce config.sops.templates."pg_hba_auth.conf".path;
    };
    # NOTE: DO NOT USE `services.postgresql.authentication`, because I use SOPS-templateed
    # `services.postgresql.settings.hba_file` instead
    ensureDatabases = [
      "playground" # TODO: For learning
      "atuin"
      machine_cfg.paperless.services.paperless.user
      machine_cfg.authelia.services.authelia.instances.main.user
      # (builtins.trace machine_config.authelia machine_config.authelia.services.authelia.instances.main.user)
      "nextcloud"
      "grafana"
    ];
    ensureUsers = [
      {
        name = "proteus";
        ensureClauses = {
          login = true;
          # superuser = true;
          createdb = true;
        };
      }
      {
        name = "atuin";
        ensureDBOwnership = true;
      }
      {
        name = machine_cfg.paperless.services.paperless.user;
        ensureDBOwnership = true;
      }
      {
        name = machine_cfg.authelia.services.authelia.instances.main.user;
        ensureDBOwnership = true;
      }
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
      {
        name = "grafana";
        ensureDBOwnership = true;
      }
    ];
  };
  services.postgresqlBackup = {
    enable = true;
    startAt = const.backupTimes.postgresql;
    # databases = ["docspell"];
    # location = "/srv/Backups/psql";
    location = backup_location;
    compression = "zstd";
    compressionLevel = 3;
  };
  systemd.tmpfiles.settings =
    let
      cfg = config.services.postgresqlBackup;
    in
    lib.mkIf cfg.enable {
      "10-postgresqlBackup-change-group".${cfg.location}.z = {
        mode = "2770";
        group = "storage";
      };
    };
  systemd.services.postgresqlBackup.serviceConfig.ExecStartPost = [
    "+${pkgs.coreutils}/bin/chmod -R g+r ${config.services.postgresqlBackup.location}"
  ];
}

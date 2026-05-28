## To restore a clean backup:
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
  myvars,
  # nixpkgs-postgresql,
  pkgs,
  ...
}:
let
  backup_location = "${myvars.storagePath}/psql";
  machine_config = {
    authelia = machineConfigs.${myvars.networking.findHost "auth"}.config;
    paperless = machineConfigs.${myvars.networking.findHost "paperless"}.config;
    immich = machineConfigs.${myvars.networking.findHost "immich"}.config;
  };
in
{
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
        sopsFile = "${myvars.secretsDir}/proteus_server.priv.pem.sops";
        format = "binary";
        owner = config.systemd.services.postgresql.serviceConfig.User;
      };
      postgres_ldap_bind_pw = {
        inherit restartUnits;
        sopsFile = "${myvars.secretsDir}/${config.networking.hostName}.sops.yaml";
      };
    };
  # Ref: https://github.com/NixOS/nixpkgs/blob/549bd84d6279f9852cae6225e372cc67fb91a4c1/nixos/modules/services/databases/postgresql.nix#L684
  sops.templates."pg_hba_auth.conf" =
    let
      base_dn = "dc=" + builtins.replaceStrings [ "." ] [ ",dc=" ] myvars.domain;
    in
    {
      content =
        let
          ldap_opts = builtins.concatStringsSep " " [
            ''ldapurl="ldaps://ldap.${myvars.domain}/${base_dn}?uid?sub"''
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
    package = pkgs.postgresql.override { ldapSupport = true; };
    enableJIT = true;
    enableTCPIP = true;
    settings = {
      ssl = true;
      ssl_min_protocol_version = "TLSv1.3";
      ssl_cert_file = "${myvars.secretsDir}/proteus_server.pub.pem";
      ssl_key_file = config.sops.secrets."postgresql_server.priv.pem".path;
      hba_file = lib.mkForce config.sops.templates."pg_hba_auth.conf".path;
    };
    ensureDatabases = [
      "mydatabase" # TODO: For learning
      "atuin"
      machine_config.paperless.services.paperless.user
      machine_config.authelia.services.authelia.instances.main.user
      # (builtins.trace machine_config.authelia machine_config.authelia.services.authelia.instances.main.user)
      "nextcloud"
      machine_config.immich.services.immich.database.user
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
        name = machine_config.paperless.services.paperless.user;
        ensureDBOwnership = true;
      }
      {
        name = machine_config.authelia.services.authelia.instances.main.user;
        ensureDBOwnership = true;
      }
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
      {
        name = machine_config.immich.services.immich.database.user;
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
    # Immich
    extensions = ps: [
      ps.pgvector
      ps.vectorchord
    ];
    settings = {
      shared_preload_libraries = [ "vchord.so" ];
      search_path = "\"$user\", public, vectors";
    };

    # DO NOT USE `services.postgresql.authentication`, because I use SOPS-templateed
    # `services.postgresql.settings.hba_file` instead
  };
  services.postgresqlBackup = {
    enable = true;
    startAt = myvars.backupTimes.postgresql;
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

  systemd.services.postgresql-setup.serviceConfig.ExecStartPost =
    let
      extensions = [
        "unaccent"
        "uuid-ossp"
        "cube"
        "earthdistance"
        "pg_trgm"
        "vector"
        "vchord"
      ];
      sqlFile = pkgs.writeText "immich-pgvectors-setup.sql" ''
        -- save previous version of vectorchord to trigger reindex on update
        SELECT COALESCE(installed_version, ''') AS vchord_version_before FROM pg_available_extensions WHERE name = 'vchord' \gset

        ${lib.concatMapStringsSep "\n" (ext: "CREATE EXTENSION IF NOT EXISTS \"${ext}\";") extensions}
        ${lib.concatMapStringsSep "\n" (ext: "ALTER EXTENSION \"${ext}\" UPDATE;") extensions}
        ALTER SCHEMA public OWNER TO ${machine_config.immich.services.immich.database.user};

        -- trigger reindex if vectorchord updates
        -- https://docs.immich.app/administration/postgres-standalone/#updating-vectorchord
        SELECT COALESCE(installed_version, ''') AS vchord_version_after FROM pg_available_extensions WHERE name = 'vchord' \gset

        SELECT (:'vchord_version_before' != ''' AND :'vchord_version_before' != :'vchord_version_after') AS has_vchord_updated \gset
        \if :has_vchord_updated
          REINDEX INDEX face_index;
          REINDEX INDEX clip_index;
        \endif
      '';
    in
    [
      ''
        ${lib.getExe' config.services.postgresql.package "psql"} -d "${machine_config.immich.services.immich.database.name}" -f "${sqlFile}"
      ''
    ];
}

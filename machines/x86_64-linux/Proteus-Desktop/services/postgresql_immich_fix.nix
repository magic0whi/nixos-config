{
  const,
  config,
  lib,
  machineConfigs,
  pkgs,
  ...
}:
let
  machine_config.immich = machineConfigs.${const.networking.findFirstHostBySubdomain "immich"}.config;
in
{
  services.postgresql = {
    ensureDatabases = [
      machine_config.immich.services.immich.database.user
    ];
    ensureUsers = [
      {
        name = machine_config.immich.services.immich.database.user;
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
    extensions = ps: [
      ps.pgvector
      ps.vectorchord
    ];
    settings = {
      shared_preload_libraries = [ "vchord.so" ];
      search_path = "\"$user\", public, vectors";
    };

  };
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

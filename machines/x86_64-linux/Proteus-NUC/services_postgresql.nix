{
  config,
  lib,
  myvars,
  # nixpkgs-postgresql,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [config.services.postgresql.settings.port];
  sops.secrets = let
    restartUnits = ["postgresql.service" "postgresql-setup.service"];
  in {
    "postgresql_server.priv.pem" = {
      inherit restartUnits;
      sopsFile = "${myvars.secrets_dir}/proteus_server.priv.pem.sops";
      format = "binary";
      owner = config.systemd.services.postgresql.serviceConfig.User;
    };
    postgres_ldap_bind_pw = {
      inherit restartUnits;
      sopsFile = "${myvars.secrets_dir}/${config.networking.hostName}.sops.yaml";
    };
  };
  # Ref: https://github.com/NixOS/nixpkgs/blob/549bd84d6279f9852cae6225e372cc67fb91a4c1/nixos/modules/services/databases/postgresql.nix#L684
  sops.templates."pg_hba_auth.conf" = let
    base_dn = "dc=" + builtins.replaceStrings ["."] [",dc="] myvars.domain;
  in {
    content = ''
      # Generated file; do not edit!

      # type database DBuser auth-method [auth-options]
      local all all trust
      # The ?sub part tells the server to perform a "subtree" search. It will traverse down into both `ou=People` and
      # `ou=ServiceAccounts` to find the matching uid
      host all all 0.0.0.0/0 ldap ldapurl="ldaps://ldap.${myvars.domain}/${base_dn}?uid?sub" ldapbinddn="uid=${config.systemd.services.postgresql.serviceConfig.User},ou=ServiceAccounts,${base_dn}" ldapbindpasswd="${config.sops.placeholder.postgres_ldap_bind_pw}"
      host all all ::/0 ldap ldapurl="ldaps://ldap.${myvars.domain}/${base_dn}?uid?sub" ldapbinddn="uid=${config.systemd.services.postgresql.serviceConfig.User},ou=ServiceAccounts,${base_dn}" ldapbindpasswd="${config.sops.placeholder.postgres_ldap_bind_pw}"

      # default value of `services.postgresql.authentication`
      local all postgres         peer map=postgres
      local all all              peer
      host  all all 127.0.0.1/32 md5
      host  all all ::1/128      md5
    '';
    owner = config.systemd.services.postgresql.serviceConfig.User;
    restartUnits = ["postgresql.service" "postgresql-setup.service"];
  };
  # TODO: Learn SQL
  services.postgresql = {
    enable = true;
    # package = nixpkgs-postgresql.legacyPackages.${
    #   pkgs.stdenv.hostPlatform.system
    # }.postgresql.override {ldapSupport = true;};
    package = pkgs.postgresql.override {ldapSupport = true;};
    enableJIT = true;
    enableTCPIP = true;
    settings = {
      ssl = true;
      ssl_cert_file = "${myvars.secrets_dir}/proteus_server.pub.pem";
      ssl_key_file = config.sops.secrets."postgresql_server.priv.pem".path;
      hba_file = lib.mkForce config.sops.templates."pg_hba_auth.conf".path;
    };
    ensureDatabases = [
      "mydatabase" # TODO: For learning
      "atuin"
      config.services.paperless.user
      config.services.authelia.instances.main.user
      "nextcloud"
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
        name = config.services.paperless.user;
        ensureDBOwnership = true;
      }
      {
        name = config.services.authelia.instances.main.user;
        ensureDBOwnership = true;
      }
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
    ];
    # DO NOT USE `services.postgresql.authentication`, because I use SOPS-templateed
    # `services.postgresql.settings.hba_file` instead
  };
  services.postgresqlBackup = {
    enable = true;
    startAt = myvars.backup_times.postgresql;
    # databases = ["docspell"];
    location = "/srv/Backups/psql";
    compression = "zstd";
    compressionLevel = 3;
  };
  systemd.tmpfiles.settings = let
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

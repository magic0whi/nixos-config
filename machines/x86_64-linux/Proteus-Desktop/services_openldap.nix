{
  config,
  lib,
  machineConfigs,
  myvars,
  pkgs,
  ...
}:
let
  machine_config = {
    authelia = machineConfigs.${myvars.networking.findHost "auth"}.config;
    forgejo = machineConfigs.${myvars.networking.findHost "git"}.config;
    immich = machineConfigs.${myvars.networking.findHost "immich"}.config;
    paperless = machineConfigs.${myvars.networking.findHost "paperless"}.config;
    postgresql = machineConfigs.${myvars.networking.findHost "postgresql"}.config;
  };

  openldap_port = 636; # OpenLDAP (Secure)
  openldap_backend_port = 389;
in
{
  networking.firewall.allowedTCPPorts = [ openldap_port ]; # UDP generally not used
  services.openldap =
    let
      base_dn = "dc=" + builtins.replaceStrings [ "." ] [ ",dc=" ] myvars.domain;
      manager_dn = "cn=Manager,${base_dn}";
    in
    {
      enable = true;
      # If use `ldaps:///`, the `///` tells OpenLDAP to bind to the default port on all available network interfaces (
      # `0.0.0.0` and `::`)
      urlList = [
        "pldap://127.0.0.1:${toString openldap_backend_port}/"
        "pldap://[::1]:${toString openldap_backend_port}/"
      ];
      settings = {
        # dn: cn=config
        attrs = {
          # cn: config
          # objectClass: olcGlobal
          olcLogLevel = [ "stats" ];
          # olcTLSCertificateFile = server_pub_crt;
          # olcTLSCertificateKeyFile = server_priv_crt;
          # olcTLSCipherSuite = "DEFAULT:!kRSA:!kDHE";
          # olcTLSProtocolMin = "3.3"; # 3.4 for tls1.3
        };
        children = {
          "cn=module".attrs = {
            objectClass = "olcModuleList";
            olcModuleLoad = [ "argon2" ];
          };
          "cn=schema".includes = with pkgs; [
            "${openldap}/etc/schema/core.ldif"
            "${openldap}/etc/schema/cosine.ldif"
            "${myvars.secrets_dir}/rfc2307bis.ldif"
            "${openldap}/etc/schema/inetorgperson.ldif"
          ];
          "olcDatabase={0}config".attrs = {
            objectClass = "olcDatabaseConfig";
            olcDatabase = "{0}config";
            olcAccess = [ "{0}to * by * none break" ];
            olcRootDN = manager_dn;
          };
          "olcDatabase={1}mdb".attrs = {
            objectClass = [
              "olcDatabaseConfig"
              "olcMdbConfig"
            ];
            olcDatabase = "{1}mdb";
            olcSuffix = base_dn;
            olcRootDN = manager_dn;
            # TIP: To generate password digest
            # `slappasswd -o module-load=argon2 -h '{ARGON2}'`
            # or `slappasswd -o module-load=pw-pbkdf2.la -h '{PBKDF2-SHA512}'``
            # To verify:
            # `systemd-ask-password -n | nix run nixpkgs#libargon2 -- "$(echo -n 'jIm9hSEdZYbgTAjqXx85IQ' | base64 -d)" -id -v 13 -m 16 -t 2 -p 1`
            olcRootPW = "{ARGON2}$argon2id$v=19$m=65536,t=2,p=1$jIm9hSEdZYbgTAjqXx85IQ$ugObSc6CHpUPirGXr5v1DFFm29ux7HH1AGtOFN//XaQ";
            olcDbDirectory = "/var/lib/openldap/openldap-data";
            olcDbIndex = [
              "objectClass eq"
              "uid pres,eq"
              "cn,sn,mail pres,sub,eq"
              "dc eq"
            ];
            olcAccess = [
              (builtins.concatStringsSep " " [
                "{0}to attrs=userPassword,shadowLastChange,photo" # Rule {0}: Sensitive Attributes
                "by self write" # Users are allowed to update their own userPassword, shadowLastChange, photo
                # Unauthenticated (anonymous) users can use these attributes solely for the purpose of logging in
                # (authentication). They cannot read the actual password hashes.
                "by anonymous auth"
                # The system administrator (defined by the ${manager_dn} variable) has full permission to modify these
                # attributes.
                "by dn.base=\"${manager_dn}\" write"
                "by * none" # Everyone else is explicitly denied access
              ])
              (builtins.concatStringsSep " " [
                "{1}to *" # Rule {1}: Catch-all Rule
                # Through already covered by `by users read` below, keep it
                # for explicitly defines user self-access
                "by self read"
                "by dn.base=\"${manager_dn}\" write"
                # Any authenticated user can read all general directory entries and attributes
                "by users read"
                "by anonymous auth"
              ])
            ];
          };
        };
      };
      declarativeContents."${base_dn}" = ''
        dn: ${base_dn}
        objectClass: dcObject
        objectClass: organization
        dc: ${lib.removePrefix "dc=" (builtins.head (lib.splitString "," base_dn))}
        o: Proteus Homelab

        dn: ${manager_dn}
        objectClass: top
        objectClass: organizationalRole
        cn: Manager
        description: LDAP administrator
        roleOccupant: ${base_dn}

        dn: ou=People,${base_dn}
        objectClass: top
        objectClass: organizationalUnit
        ou: People

        dn: ou=Group,${base_dn}
        objectClass: top
        objectClass: organizationalUnit
        ou: Group

        dn: ou=Sudoers,${base_dn}
        objectClass: top
        objectClass: organizationalUnit
        ou: Sudoers

        dn: ou=ServiceAccounts,${base_dn}
        objectClass: top
        objectClass: organizationalUnit
        ou: ServiceAccounts

        dn: uid=${myvars.username},ou=People,${base_dn}
        objectClass: top
        objectClass: person
        objectClass: organizationalPerson
        objectClass: inetOrgPerson
        objectClass: posixAccount
        objectClass: shadowAccount
        uid: ${myvars.username}
        cn: ${myvars.userfullname}
        sn: Qian
        givenName: Proteus
        title: Qiansan
        mail: ${myvars.useremail}
        labeledURI: http://misc.s3-pub.proteus.eu.org/siameseemoji_agadmqeaaspumeu.png
        loginShell: /bin/zsh
        uidNumber: ${toString config.users.users.${myvars.username}.uid}
        gidNumber: ${toString config.users.groups.users.gid}
        homeDirectory: ${config.users.users.${myvars.username}.home}
        description: Primary personal account
        userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$arVKdAqitf39aAVGaLS5Qw$AtzBSJDhT9vsiLg6ZhZDuHxH5euYqlVmGSE+EWjlxqs

        dn: uid=atuin,ou=ServiceAccounts,${base_dn}
        objectClass: top
        objectClass: person
        objectClass: organizationalPerson
        objectClass: inetOrgPerson
        # objectClass: posixAccount
        uid: atuin
        o: Proteus Homelab
        cn: Atuin Database Auth Service
        sn: Service
        # loginShell: ${lib.getExe' pkgs.shadow "nologin"}
        # homeDirectory: /var/empty
        description: Dedicated LDAP account for authenticating database user
        userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$2/qpzCZL/QW5fczhx60Bwg$64zn/anj0LiNqsupuKnr5UA7B+Ejm3H+JL29NgSqwVs

        dn: uid=${machine_config.postgresql.systemd.services.postgresql.serviceConfig.User},ou=ServiceAccounts,${base_dn}
        objectClass: top
        objectClass: person
        objectClass: organizationalPerson
        objectClass: inetOrgPerson
        uid: ${machine_config.postgresql.systemd.services.postgresql.serviceConfig.User}
        o: Proteus Homelab
        cn: PostgreSQL Database Auth Service
        sn: Service
        description: Dedicated LDAP account for authenticating database user
        userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$gAW72T0XdGEPASN6Lw93pw$IoCTZ5kgwFaGAAt92SBp36hglEn/oU3BvY4et8xRY68

        dn: uid=${machine_config.immich.services.immich.user},ou=ServiceAccounts,${base_dn}
        objectClass: top
        objectClass: person
        objectClass: organizationalPerson
        objectClass: inetOrgPerson
        uid: ${machine_config.immich.services.immich.user}
        o: Proteus Homelab
        cn: Immich Database Auth Service
        sn: Service
        description: Dedicated LDAP account for authenticating database user
        userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$OEpAKFVxRbsfk8djqOY2yg$scRgt8huwIp6bmRTbKxHdf5YzDqbc+sv5O6FdnF59+s

        dn: uid=${machine_config.paperless.services.paperless.user},ou=ServiceAccounts,${base_dn}
        objectClass: top
        objectClass: person
        objectClass: organizationalPerson
        objectClass: inetOrgPerson
        uid: ${machine_config.paperless.services.paperless.user}
        o: Proteus Homelab
        sn: Service
        cn: Paperless Database Auth Service
        description: Dedicated LDAP account for authenticating database user
        userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$ZCKwwHl/8qfXSbgipXXHww$XJWgXYKm8jy4WxhITOkBDLWZi0GhfCLYwpSrgtkhMus

        dn: uid=${machine_config.authelia.services.authelia.instances.main.user},ou=ServiceAccounts,${base_dn}
        objectClass: top
        objectClass: person
        objectClass: organizationalPerson
        objectClass: inetOrgPerson
        uid: ${machine_config.authelia.services.authelia.instances.main.user}
        o: Proteus Homelab
        sn: Service
        cn: Authelia Service & Authelia Database Auth Service
        description: Dedicated LDAP account for Authelia to query the directory & authenticating database user
        userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$FO5I3Wn6CsduQpv15iZBXQ$B3LtuuB/+5kcJ8gl6ikcN2XgBUK+qdzLNA1Yp93QonM

        dn: uid=nextcloud,ou=ServiceAccounts,${base_dn}
        objectClass: top
        objectClass: person
        objectClass: organizationalPerson
        objectClass: inetOrgPerson
        uid: nextcloud
        o: Proteus Homelab
        sn: Service
        cn: Nextcloud Database Auth Service
        description: Dedicated LDAP account for authenticating database user
        userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$KW1J9YdPNePdvjKAr07C3Q$QvyeZxYPF4BBNJGU4/lJuY2ecV1zBQ5RSjz0gxDzKAg

        dn: uid=sssd,ou=ServiceAccounts,${base_dn}
        objectClass: top
        objectClass: person
        objectClass: organizationalPerson
        objectClass: inetOrgPerson
        uid: sssd
        o: Proteus Homelab
        sn: Service
        cn: SSSD Service
        description: Dedicated LDAP account for SSSD to query the directory
        userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$I71nfOU2bdoCUvbHZ6lcaA$uCcQtwCSNYzjnx8KlyaU6nb0zDZQHiL2Cf9IGLskr8M

        dn: uid=${machine_config.forgejo.services.forgejo.user},ou=ServiceAccounts,${base_dn}
        objectClass: top
        objectClass: person
        objectClass: organizationalPerson
        objectClass: inetOrgPerson
        uid: ${machine_config.forgejo.services.forgejo.user}
        o: Proteus Homelab
        sn: Service
        cn: Forgejo Database Auth Service
        description: Dedicated LDAP account for authenticating database user
        userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$Lk6YxoylMGkd2YaTXwYl2g$D/13/TdjrjezdOg3zhEgeI6UJvH9BMZb/xjNPcg17BE

        dn: cn=storage,ou=Group,${base_dn}
        objectClass: top
        objectClass: posixGroup
        objectClass: groupOfMembers
        cn: storage
        gidNumber: ${toString config.users.groups.storage.gid}
        description: Group to share directory across multiple users
        member: uid=${myvars.username},ou=People,${base_dn}

        dn: cn=jellyfin-admins,ou=Group,${base_dn}
        objectClass: top
        objectClass: groupOfMembers
        cn: jellyfin-admins
        description: Group to set Jellyfin Admins
        member: uid=${myvars.username},ou=People,${base_dn}

      '';
    };
  services.traefik = {
    staticConfigOptions.entryPoints.ldaps.address = ":${toString openldap_port}";
    dynamicConfigOptions.tcp = {
      routers.openldap = {
        # Catch-all rule for traffic on this port. standard LDAP clients (like ldapsearch and many older legacy systems)
        # do not send SNI data.
        rule = "HostSNI(`*`)";
        entryPoints = [ "ldaps" ];
        service = "openldap";
        tls = { };
      };
      services.openldap.loadBalancer = {
        proxyProtocol.version = 2; # Instruct Traefik to inject the PROXY protocol v2 header
        servers = [
          { address = "127.0.0.1:${toString openldap_backend_port}"; }
          { address = "[::1]:${toString openldap_backend_port}"; }
        ];
      };
    };
  };
}

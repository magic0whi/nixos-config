{
  baseDN,
  pkgs,
  lib,
  machineConfigs,
  const,
  ...
}:
let
  machine_config = {
    authelia = machineConfigs.${const.networking.findFirstHostBySubdomain "auth"}.config;
    forgejo = machineConfigs.${const.networking.findFirstHostBySubdomain "git"}.config;
    immich = machineConfigs.${const.networking.findFirstHostBySubdomain "immich"}.config;
    paperless = machineConfigs.${const.networking.findFirstHostBySubdomain "paperless"}.config;
    postgresql = machineConfigs.${const.networking.findFirstHostBySubdomain "postgresql"}.config;
    niks3 = machineConfigs.${const.networking.findFirstHostBySubdomain "niks3"}.config;
  };
in
''
  dn: ou=ServiceAccounts,${baseDN}
  objectClass: top
  objectClass: organizationalUnit
  ou: ServiceAccounts

  dn: uid=atuin,ou=ServiceAccounts,${baseDN}
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

  dn: uid=${machine_config.postgresql.systemd.services.postgresql.serviceConfig.User},ou=ServiceAccounts,${baseDN}
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

  dn: uid=${machine_config.immich.services.immich.user},ou=ServiceAccounts,${baseDN}
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

  dn: uid=${machine_config.paperless.services.paperless.user},ou=ServiceAccounts,${baseDN}
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

  dn: uid=${machine_config.authelia.services.authelia.instances.main.user},ou=ServiceAccounts,${baseDN}
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

  dn: uid=nextcloud,ou=ServiceAccounts,${baseDN}
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

  dn: uid=sssd,ou=ServiceAccounts,${baseDN}
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

  dn: uid=${machine_config.forgejo.services.forgejo.user},ou=ServiceAccounts,${baseDN}
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

  dn: uid=${machine_config.niks3.services.niks3.user},ou=ServiceAccounts,${baseDN}
  objectClass: top
  objectClass: person
  objectClass: organizationalPerson
  objectClass: inetOrgPerson
  uid: ${machine_config.niks3.services.niks3.user}
  o: Proteus Homelab
  sn: Service
  cn: Niks3 Database Auth Service
  description: Dedicated LDAP account for authenticating database user
  userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$P2vBvDvBSv852DZE6hK+KQ$Mx9X6tARLOFI/r8mDnyN9ib6xEXj+XtRY3kLYaXrxqs

  dn: uid=grafana,ou=ServiceAccounts,${baseDN}
  objectClass: top
  objectClass: person
  objectClass: organizationalPerson
  objectClass: inetOrgPerson
  uid: grafana
  o: Proteus Homelab
  cn: Grafana Database Auth Service
  sn: Service
  description: Dedicated LDAP account for authenticating database user and prometheus user
  userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$JQgfWUpO29+6dRxSw4ubiQ$rOHob39QO18/4PIxhmvHOpMOo1bBdDrMMgB7NP7NvLY
''

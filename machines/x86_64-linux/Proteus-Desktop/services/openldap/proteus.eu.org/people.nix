{
  config,
  baseDN,
  const,
  ...
}:
''
  dn: ou=People,${baseDN}
  objectClass: top
  objectClass: organizationalUnit
  ou: People

  dn: uid=${const.username},ou=People,${baseDN}
  objectClass: top
  objectClass: person
  objectClass: organizationalPerson
  objectClass: inetOrgPerson
  objectClass: posixAccount
  objectClass: shadowAccount
  uid: ${const.username}
  cn: ${const.userFullName}
  sn: Qian
  givenName: Proteus
  title: Qiansan
  mail: ${const.email}
  labeledURI: https://misc.s3-pub.proteus.eu.org/siameseemoji_agadmqeaaspumeu.png
  loginShell: /bin/zsh
  uidNumber: ${toString config.users.users.${const.username}.uid}
  gidNumber: ${toString config.users.groups.users.gid}
  homeDirectory: ${config.users.users.${const.username}.home}
  description: Primary personal account
  userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$arVKdAqitf39aAVGaLS5Qw$AtzBSJDhT9vsiLg6ZhZDuHxH5euYqlVmGSE+EWjlxqs

  dn: uid=father,ou=People,${baseDN}
  objectClass: top
  objectClass: person
  objectClass: organizationalPerson
  objectClass: inetOrgPerson
  uid: father
  cn: Father Family
  sn: Family
  givenName: Father
  mail: father@${const.domain}
  description: Account for self-hosted services
  userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$Qy12Udyu8BwhldnhxmpVsw$xk5lHJKFZtLYFUICPiDu2DhPL5vgZFRe9SIrt8dSw8Q

  dn: uid=mother,ou=People,${baseDN}
  objectClass: top
  objectClass: person
  objectClass: organizationalPerson
  objectClass: inetOrgPerson
  uid: mother
  cn: Mother Family
  sn: Family
  givenName: Mother
  mail: mother@${const.domain}
  description: Account for self-hosted services
  userPassword: {ARGON2}$argon2id$v=19$m=65536,t=2,p=1$MMxZvGZmYifIMYiqnhnrGA$PWpb8eA3O1bdScJ5wRAj0c7iBUnoYn/6eZin5yx9Vvc
''

{
  config,
  const,
  baseDN,
  ...
}:
''
  dn: ou=Group,${baseDN}
  objectClass: top
  objectClass: organizationalUnit
  ou: Group

  dn: cn=storage,ou=Group,${baseDN}
  objectClass: top
  objectClass: posixGroup
  objectClass: groupOfMembers
  cn: storage
  gidNumber: ${toString config.users.groups.storage.gid}
  description: Group to share directory across multiple users
  member: uid=${const.username},ou=People,${baseDN}

  dn: cn=admins,ou=Group,${baseDN}
  objectClass: top
  objectClass: groupOfMembers
  cn: admins
  description: Group to set Admins
  member: uid=${const.username},ou=People,${baseDN}
''

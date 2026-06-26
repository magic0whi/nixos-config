args@{
  baseDN,
  lib,
  mylib,
  ...
}:
lib.mkMerge (
  lib.singleton ''
    dn: ${baseDN}
    objectClass: dcObject
    objectClass: organization
    dc: ${lib.removePrefix "dc=" (builtins.head (lib.splitString "," baseDN))}
    o: Proteus Homelab

    dn: ou=Sudoers,${baseDN}
    objectClass: top
    objectClass: organizationalUnit
    ou: Sudoers
  ''
  ++ map (file: import file args) (mylib.scanPath ./.)
)

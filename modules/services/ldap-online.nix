{ const, pkgs, ... }:
{
  # To use it, add `ldap-online.service` to a unit's `wants` and `after`
  systemd.services.ldap-online = {
    description = "Wait for LDAP (ldap.${const.domain}) to be online";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    # No `RemainAfterExit`, so the check re-runs every time a consumer starts, e.g. when openldap restarts in the same
    # deploy transaction
    serviceConfig.Type = "oneshot";
    # LDAP may sit behind a reverse proxy (e.g. Traefik), which accepts TCP connections before slapd is up, so `nc -z`
    # is not enough; do a real (anonymous rootDSE) LDAP query instead
    script = ''
      echo "Waiting for LDAP (ldap.${const.domain}) to be ready..."
      until ${pkgs.openldap}/bin/ldapsearch -x -H 'ldaps://ldap.${const.domain}' -b "" -s base -o nettimeout=5 \
        >/dev/null 2>&1; do
        sleep 2
      done
      echo "LDAP is online."
    '';
  };
}

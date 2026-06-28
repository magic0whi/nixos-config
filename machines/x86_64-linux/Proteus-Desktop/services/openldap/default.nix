{
  config,
  lib,
  machineConfigs,
  const,
  pkgs,
  mylib,
  ...
}:
let

  openldap_port = 636; # OpenLDAP (Secure)
  openldap_backend_port = 389;
in
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "ldap" ];
        AAAA = [ "ldap" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  networking.firewall.allowedTCPPorts = [ openldap_port ]; # UDP generally not used
  services.openldap =
    let
      base_dn = "dc=" + builtins.replaceStrings [ "." ] [ ",dc=" ] const.domain;
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
            olcModuleLoad = [
              "argon2"
              "pw-pbkdf2"
            ];
          };
          "cn=schema".includes = with pkgs; [
            "${openldap}/etc/schema/core.ldif"
            "${openldap}/etc/schema/cosine.ldif"
            "${const.secretsDir}/rfc2307bis.ldif"
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
            # `nix shell nixpkgs#openldap -c slappasswd -o module-load=argon2 -h '{ARGON2}'`
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
      declarativeContents."${base_dn}" = lib.mkMerge [
        ''
          dn: ${manager_dn}
          objectClass: top
          objectClass: organizationalRole
          cn: Manager
          description: LDAP administrator
          roleOccupant: ${base_dn}
        ''
        (import ./proteus.eu.org {
          baseDN = base_dn;
          inherit
            config
            const
            lib
            machineConfigs
            pkgs
            mylib
            ;
        })
      ];
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

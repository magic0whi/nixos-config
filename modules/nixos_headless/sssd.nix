{ config, const, ... }:
{
  system.nssDatabases.sudoers = [ "sss" ]; # Use LDAP to distribute configuration of sudo as well
  sops =
    let
      restartUnits = [ "sssd.service" ];
      sopsFile = "${const.secretsDir}/common.sops.yaml";
    in
    {
      secrets."sssd_ldap_default_authtok" = { inherit sopsFile restartUnits; };
      templates."sssd.env" = {
        # https://github.com/NixOS/nixpkgs/blob/15f4ee454b1dce334612fa6843b3e05cf546efab/nixos/modules/services/misc/sssd.nix#L111-L113
        inherit restartUnits;
        content = "SSSD_LDAP_DEFAULT_AUTHTOK='${config.sops.placeholder.sssd_ldap_default_authtok}'";
      };
    };
  services.sssd = {
    enable = true;
    environmentFile = config.sops.templates."sssd.env".path;
    settings = {
      sssd = {
        # debug_level = 7;
        services = "ifp, nss, pam, sudo";
        domains = "LDAP";
      };
      # "pam".pam_verbosity = 3;
      "domain/LDAP" =
        let
          base_dn = "dc=" + builtins.replaceStrings [ "." ] [ ",dc=" ] const.domain;
        in
        {
          override_shell = "/run/current-system/sw/bin/${config.users.defaultUserShell.meta.mainProgram}";
          cache_credentials = true;
          entry_cache_timeout = 600;
          enumerate = true;

          id_provider = "ldap";
          auth_provider = "ldap";
          chpass_provider = "ldap";

          ldap_uri = "ldaps://ldap.${const.domain}:636";
          ldap_default_bind_dn = "uid=sssd,ou=ServiceAccounts,${base_dn}";
          ldap_default_authtok = "$SSSD_LDAP_DEFAULT_AUTHTOK";
          ldap_search_base = base_dn;
          ldap_sudo_search_base = "ou=Sudoers,${base_dn}";
          ldap_tls_reqcert = "demand";
          ldap_network_timeout = 2;
          ldap_schema = "rfc2307bis";
        };
    };
  };
}

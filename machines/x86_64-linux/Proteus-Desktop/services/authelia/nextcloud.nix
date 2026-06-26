# Ref: https://www.authelia.com/integration/openid-connect/clients/nextcloud/
{ lib, const, ... }:
{
  services.authelia.instances.main.settings = {
    # Define the expression to evaluate the custom attribute
    # Evaluates admin privilege for Nextcloud. Change the group name if needed.
    # Ref: https://www.authelia.com/configuration/definitions/user-attributes/
    definitions.user_attributes.is_nextcloud_admin.expression = ''"storage" in groups'';

    identity_providers.oidc = {
      claims_policies = {
        # Give the 'is_nextcloud_admin' claim policy access to the user attributes 'is_nextcloud_admin'
        # Authelia do implicit mapping, this equivalent to {attribute = "is_nextcloud_admin";};
        nextcloud_userinfo_policy.custom_claims.is_nextcloud_admin = { };

        # Give the 'homeDirectory' claim policy access to the ldap extra attributes 'home_directory'
        # Disabled as I don't want external storage to mount my home directory
        # homeDirectory = {attribute = "home_directory";};
      };
      # Bind the claim to the `nextcloud_userinfo` scope
      scopes.nextcloud_userinfo.claims = [
        "is_nextcloud_admin"
        # "homeDirectory"
      ];
      clients = lib.singleton {
        client_id = "nextcloud";
        client_name = "Nextcloud";
        client_secret = "$pbkdf2-sha512$310000$Nf0RYQUukNM3r/FVDi/YDA$RCvY0zSeZFvJgr4F4bubUdBfWbMiL2rQe7oKjoj0995XQNaDrzl4ZfVBDoyBjVipQIVgIvTCcSRN2Ak6Vv7jfQ";
        require_pkce = true;
        pkce_challenge_method = "S256";
        claims_policy = "nextcloud_userinfo_policy";
        redirect_uris = [ "https://nextcloud.${const.domain}/apps/oidc_login/oidc" ];
        scopes = [
          "openid"
          "email"
          "profile"
          "groups"
          "nextcloud_userinfo"
        ];
      };
    };
  };
}

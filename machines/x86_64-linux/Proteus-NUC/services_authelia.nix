{
  config,
  lib,
  mylib,
  myvars,
  ...
}: let
  restartUnits = map (name: "authelia-${name}.service") (builtins.attrNames config.services.authelia.instances);
in {
  sops.secrets = let
    sopsFile = "${myvars.secrets_dir}/${config.networking.hostName}.sops.yaml";
    owner = config.services.authelia.instances.main.user;
  in {
    authelia_jwt_secret = {inherit sopsFile owner restartUnits;};
    authelia_session_secret = {inherit sopsFile owner restartUnits;};
    authelia_storage_encryption_key = {inherit sopsFile owner restartUnits;};
    authelia_ldap_password = {inherit sopsFile owner restartUnits;};
    authelia_oidc_hmac = {inherit sopsFile owner restartUnits;};
    "authelia_oidc_rsa.pem" = {
      inherit owner restartUnits;
      sopsFile = "${myvars.secrets_dir}/authelia_oidc_rsa.pem.sops";
      format = "binary";
    };
  };
  systemd.services = let
    clean_units = map (s: lib.removeSuffix ".service" s) restartUnits;
  in
    lib.mkMerge [
      (
        lib.genAttrs
        clean_units (_: {serviceConfig.SupplementaryGroups = [config.services.redis.servers.authelia.group];})
      )
    ];

  services.redis.servers.authelia.enable = true;

  services.authelia.instances.main = {
    enable = true;
    secrets = {
      # To generate those secrets, run
      # nix run nixpkgs#authelia -- crypto rand --length 64 session_secret.txt storage_encryption_key.txt jwt_secret.txt
      jwtSecretFile = config.sops.secrets."authelia_jwt_secret".path;
      sessionSecretFile = config.sops.secrets."authelia_session_secret".path;
      storageEncryptionKeyFile = config.sops.secrets."authelia_storage_encryption_key".path;
      oidcHmacSecretFile = config.sops.secrets."authelia_oidc_hmac".path;
      oidcIssuerPrivateKeyFile = config.sops.secrets."authelia_oidc_rsa.pem".path;
    };
    # LDAP Password Injection. Using `_FILE` suffix tells Authelia to read the contents of the secret path
    environmentVariables = {
      # Render to `settings.authentication_backend.ldap.password`
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.sops.secrets."authelia_ldap_password".path;
      # Render to `settings.storage.postgres.password`
      AUTHELIA_STORAGE_POSTGRES_PASSWORD_FILE = config.sops.secrets."authelia_ldap_password".path;
    };
    # https://github.com/authelia/authelia/blob/8a7b642dd78f29c76d126b6f53806472b2a360bd/config.template.yml
    settings = {
      theme = "dark";
      default_2fa_method = "totp";
      server.address = "tcp://127.0.0.1:9092"; # Use the new server.address syntax required by the module
      session.cookies = [
        {
          # This allows the login cookie to work across all your subdomains
          inherit (myvars) domain;
          authelia_url = "https://auth.${myvars.domain}";
          same_site = "lax";
          inactivity = "5 minutes";
          expiration = "1 hour";
          remember_me = "1 month";
        }
      ];
      session.redis.host = config.services.redis.servers.authelia.unixSocket;
      storage.postgres = {
        address = "unix:///run/postgresql/.s.PGSQL.${toString config.services.postgresql.settings.port}";
        # address = "tcp://postgresql.${myvars.domain}:${toString config.services.postgresql.settings.port}";
        # tls.minimum_version = "TLS1.3";
        database = config.services.authelia.instances.main.user;
        schema = "public";
        username = config.services.authelia.instances.main.user;
        # Password is injected via environment variable
      };
      notifier.filesystem.filename = "/var/lib/authelia-main/emails.txt"; # TODO use real email
      authentication_backend = {
        ldap = let
          base_dn = "dc=" + builtins.replaceStrings ["."] [",dc="] myvars.domain;
        in {
          implementation = "custom";
          address = "ldaps://ldap.${myvars.domain}:636";
          # password = "password"; # Password is injected via environment variable
          timeout = "5s";
          base_dn = base_dn;
          # If have multiple OUs, do not specify additional_users_dn so it searches all OUs under `base_dn`
          # additional_users_dn = "ou=People";
          users_filter = "(&({username_attribute}={input})(objectClass=person))";
          additional_groups_dn = "ou=Group";
          groups_filter = "(member={dn})";
          user = "uid=${config.services.authelia.instances.main.user},ou=ServiceAccounts,${base_dn}";
          attributes = {
            username = "uid";
            display_name = "cn";
            mail = "mail";
            group_name = "cn";
            nickname = "givenName";
            picture = "labeledURI";
            # NOTE: Here the name attribute is used for internal references within Authelia, while the attrset name is
            # the directory server attribute to search
            # Ref: https://www.authelia.com/configuration/first-factor/ldap/#extra
            # extra.homeDirectory ={name = "home_directory"; value_type = "string";};
          };
        };
      };
      access_control = {
        rules = [
          # Orders does matter
          {
            domain = "syncthing.${myvars.domain}";
            policy = "bypass";
            resources = ["^/rest/noauth/.*$"];
          }
          {
            domain = "*.${myvars.domain}";
            policy = "one_factor";
          }
        ];
        default_policy = "deny";
      };
      # Define the expression to evaluate the custom attribute
      # Evaluates admin privilege for Nextcloud. Change the group name if needed.
      # Ref: https://www.authelia.com/configuration/definitions/user-attributes/
      definitions.user_attributes.is_nextcloud_admin.expression = ''"storage" in groups'';
      identity_providers.oidc = {
        cors = {endpoints = ["authorization" "token" "revocation" "introspection" "userinfo"];};
        # Map the custom claim policy, ref:
        # https://www.authelia.com/integration/openid-connect/openid-connect-1.0-claims/#custom-claims
        claims_policies.nextcloud_userinfo.custom_claims = {
          # Give the 'is_nextcloud_admin' claim policy access to the user attributes 'is_nextcloud_admin'
          is_nextcloud_admin = {}; # Authelia do implicit mapping {attribute = "is_nextcloud_admin";};
          # Give the 'homeDirectory' claim policy access to the ldap extra attributes 'home_directory'
          # homeDirectory = {attribute = "home_directory";};
        };
        # Bind the claim to the `nextcloud_userinfo` scope
        scopes.nextcloud_userinfo.claims = [
          "is_nextcloud_admin"
          # "homeDirectory"
        ];
        # https://www.authelia.com/configuration/identity-providers/openid-connect/clients/
        clients = [
          {
            client_id = "papra";
            client_name = "Papra";
            # `nix run nixpkgs#authelia -- crypto rand --length 64 --charset alphanumeric`
            # `nix run nixpkgs#authelia -- crypto hash generate pbkdf2 --variant sha512 --password "$(systemd-ask-password)"`
            # To verify the PBKDF2 digest, run
            # `nix run nixpkgs#authelia -- crypto hash validate --password "$(systemd-ask-password)" '$pbkdf2-sha512$310000$...'`
            client_secret = "$pbkdf2-sha512$310000$3KSvvBJnoLyJDoKDBIBcZQ$dMQmccJ6Y4hrj.tv.dD3KFzLcsPCsMNRZFTpHUiInVcSX0eBR5T6jemXfcUaob9PsbgHBwRNCjtXiBNl6lOc7g";
            redirect_uris = ["https://papra.${myvars.domain}/api/auth/oauth2/callback/authelia"];
            # authorization_policy = "one_factor";
            token_endpoint_auth_method = "client_secret_post";
          }
          {
            client_id = "forgejo";
            client_name = "Forgejo";
            client_secret = "$pbkdf2-sha512$310000$hHi.uSu97kUzfh.X9ijhXA$.IL0RMznXtdwXGTYq9eKV.83nIXI0glK7v.IaFYu5xVpweng.zo5L5PpuC6aQgY6R9ROgSFQrHbve3LK50j/yg";
            redirect_uris = ["https://git.${myvars.domain}/user/oauth2/Authelia/callback"];
            require_pkce = true;
            pkce_challenge_method = "S256"; # effectively enables the require_pkce
          }
          {
            client_id = "plane";
            client_name = "Plane";
            client_secret = "$pbkdf2-sha512$310000$js.q7nxEc0JzjQN3NRyyrA$0F2fFhnC3HJspJUhFSp56F4Rl0PhzaYV.J9TytIfxZfiE7GDAuHIYKxSa262k/rf7d/vgOVHVa5a9C9P1YIYRg";
            redirect_uris = ["https://plane.${myvars.domain}/auth/gitea/callback" "https://plane.${myvars.domain}/auth/gitea/callback/"];
            scopes = ["openid" "email" "profile"];
            token_endpoint_auth_method = "client_secret_post";
          }
          {
            client_id = "paperless";
            client_name = "Paperless-ngx";
            client_secret = "$pbkdf2-sha512$310000$utOYjxWkjgXCc1TIfgg5ZQ$KA7m4g/DPTj17MWYa2nOaunrF6ZXSBlDoddd5xuCXY5cVRhgHuZ7hObedPFwRhnc772ngzbTNqy1WhANklh1CQ";
            redirect_uris = ["https://paperless.${myvars.domain}/accounts/oidc/authelia/login/callback/"];
            scopes = ["openid" "profile" "email"];
            token_endpoint_auth_method = "client_secret_post";
          }
          {
            client_id = "immich";
            client_name = "Immich";
            client_secret = "$pbkdf2-sha512$310000$JUEH012JXQCrSrfFFfk0WQ$aDVGFs8q.rusT89Kkd.d0i/HggzaGRjEXCl5XbOBSBRpQNqty5rVK/UoJJmILPJUCmd5uYZPHhiHu6HWtAE8BQ";
            redirect_uris = [
              "https://immich.${myvars.domain}/auth/login"
              "https://immich.${myvars.domain}/user-settings"
              "app.immich:///oauth-callback" # Crucial for the Immich Mobile App
            ];
            scopes = ["openid" "email" "profile"];
            token_endpoint_auth_method = "client_secret_post";
          }
          # Ref: https://www.authelia.com/integration/openid-connect/clients/nextcloud/
          {
            client_id = "nextcloud";
            client_name = "Nextcloud";
            client_secret = "$pbkdf2-sha512$310000$Nf0RYQUukNM3r/FVDi/YDA$RCvY0zSeZFvJgr4F4bubUdBfWbMiL2rQe7oKjoj0995XQNaDrzl4ZfVBDoyBjVipQIVgIvTCcSRN2Ak6Vv7jfQ";
            require_pkce = true;
            pkce_challenge_method = "S256";
            claims_policy = "nextcloud_userinfo";
            redirect_uris = ["https://nextcloud.${myvars.domain}/apps/oidc_login/oidc"];
            scopes = ["openid" "email" "profile" "groups" "nextcloud_userinfo"];
          }
          {
            client_id = "home-assistant";
            client_name = "Home Assistant";
            client_secret = "$pbkdf2-sha512$310000$L/jbJ7m.3.Xpo0oveApPUw$BFNopAMji6HRC6u7qDJDDz2bp7DWFt76IKPxURPAoqFNcbFU3/IRks2wibnh4IOjSpuVmHBtT2qAU1bu1ugldw";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = ["https://hass.${myvars.domain}/auth/oidc/callback"];
            scopes = ["openid" "profile" "groups"];
            token_endpoint_auth_method = "client_secret_post";
          }
          {
            client_id = "jellyfin";
            client_name = "Jellyfin";
            client_secret = "$pbkdf2-sha512$310000$OCHTcrIFbKQm01kTARfhRw$Lo2MFk28quOgOO.Kl29eXtS62ELRjU9XqNnN0eKK9qXvFylPHv9xdKsbLqMrHgqHAS8fHjVSE9lREuDkle1lZg";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = ["https://jellyfin.${myvars.domain}/sso/OID/redirect/authelia"];
            scopes = ["openid" "profile" "groups"];
            token_endpoint_auth_method = "client_secret_post";
          }
        ];
      };
    };
  };

  services.traefik.dynamicConfigOptions.http = let
    authelia_port = toString (mylib.get_uri_port config.services.authelia.instances.main.settings.server.address);
  in {
    middlewares.authelia-auth.forwardAuth = {
      # Tell Traefik where to ask whether a user is authenticated
      address = "http://127.0.0.1:${authelia_port}/api/authz/forward-auth?authelia_url=https://auth.${myvars.domain}/";
      trustForwardHeader = true;
      authResponseHeaders = ["Remote-User" "Remote-Groups" "Remote-Email" "Remote-Name"];
    };
    # Router for the login portal
    # `tls = {}` enables TLS using the default cert provided above
    routers.authelia = {
      rule = "Host(`auth.${myvars.domain}`)";
      entryPoints = ["websecure"];
      service = "authelia-backend";
      tls = {};
    };
    services.authelia-backend.loadBalancer = {
      servers = [{url = "http://127.0.0.1:${authelia_port}";}];
      healthCheck.path = "/api/health";
    };
  };
}

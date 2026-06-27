{
  config,
  lib,
  mylib,
  const,
  ...
}:
let
  restartUnits = map (name: "authelia-${name}.service") (builtins.attrNames config.services.authelia.instances);
in
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "auth" ];
        AAAA = [ "auth" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  sops.secrets =
    let
      sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
      owner = config.services.authelia.instances.main.user;
    in
    {
      authelia_jwt_secret = { inherit sopsFile owner restartUnits; };
      authelia_session_secret = { inherit sopsFile owner restartUnits; };
      authelia_storage_encryption_key = { inherit sopsFile owner restartUnits; };
      authelia_ldap_password = { inherit sopsFile owner restartUnits; };
      authelia_oidc_hmac = { inherit sopsFile owner restartUnits; };
      "authelia_oidc_rsa.pem" = {
        inherit owner restartUnits;
        sopsFile = "${const.secretsDir}/authelia_oidc_rsa.pem.sops";
        format = "binary";
      };
    };
  systemd.services =
    let
      clean_units = map (s: lib.removeSuffix ".service" s) restartUnits;
    in
    (lib.genAttrs clean_units (_: {
      serviceConfig.SupplementaryGroups = [ config.services.redis.servers.authelia.group ];
    }));

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
      log.level = "error";
      theme = "auto";
      default_2fa_method = "totp";
      server = {
        address = "tcp://127.0.0.1:9092"; # Use the new server.address syntax required by the module
        timeouts = {
          read = "120s";
          write = "120s";
        };
      };
      # Default: https://www.authelia.com/reference/guides/proxy-authorization/#default-endpoints
      # Config Ref: https://www.authelia.com/configuration/miscellaneous/server-endpoints-authz/#schemes
      # endpoints.authz.forward-auth = { };
      session.cookies = [
        {
          # This allows the login cookie to work across all your subdomains
          inherit (const) domain;
          authelia_url = "https://auth.${const.domain}";
          same_site = "lax";
          inactivity = "5 minutes";
          expiration = "1 hour";
          remember_me = "1 month";
        }
      ];
      session.redis.host = config.services.redis.servers.authelia.unixSocket;
      storage.postgres = {
        # Unix socket
        # address = "unix:///run/postgresql/.s.PGSQL.${toString config.services.postgresql.settings.port}";
        address = "tcp://postgresql.${const.domain}:${toString config.services.postgresql.settings.port}";
        # tls.minimum_version = "TLS1.3";
        database = config.services.authelia.instances.main.user;
        schema = "public";
        username = config.services.authelia.instances.main.user;
        # Password is injected via environment variable
      };
      notifier.filesystem.filename = "/var/lib/authelia-main/emails.txt"; # TODO use real email
      authentication_backend = {
        ldap =
          let
            base_dn = "dc=" + builtins.replaceStrings [ "." ] [ ",dc=" ] const.domain;
          in
          {
            implementation = "custom";
            address = "ldaps://ldap.${const.domain}:636";
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
            domain = "syncthing.${const.domain}";
            policy = "bypass";
            resources = [ "^/rest/noauth/.*$" ];
          }
          {
            domain = "*.${const.domain}";
            policy = "one_factor";
          }
        ];
        default_policy = "deny";
      };
      identity_providers.oidc = {
        cors = {
          endpoints = [
            "authorization"
            "token"
            "revocation"
            "introspection"
            "userinfo"
          ];
        };
        # Map the custom claim policy, ref:
        # https://www.authelia.com/integration/openid-connect/openid-connect-1.0-claims/#custom-claims
        # claims_policies = { };

        # https://www.authelia.com/configuration/identity-providers/openid-connect/clients/
        # clients = [ ]; # Splited to standalone nix files
      };
    };
  };

  services.traefik = {
    # Allowed IPs to ensure X-Forwarded-* headers (like X-Forwarded-Method) generated by Traefik on other nodes (e.g.,
    # Proteus-Desktop) are preserved and not dropped for security reasons.
    staticConfigOptions.entryPoints.websecure.forwardedHeaders.trustedIPs =
      let
        # Host services that requires OIDC
        # NOTE: I may improve it to add and use findAllHostBySumdomain if there is high availability requirements, but
        # for now just KISS to prevent over engineering
        allowed_hosts = lib.unique (map (sub: const.networking.findFirstHostBySubdomain sub) const.networking.oauthServices);
      in
      lib.concatMap (
        hostname:
        (with const.networking.allHostAddrs.${hostname}.easytier; [
          ipv4NoCidr
          ipv6NoCidr
        ])
        ++ (with const.networking.allHostAddrs.${hostname}.tailscale; [
          ipv4NoCidr
          ipv6NoCidr
        ])
      ) allowed_hosts;
    dynamicConfigOptions.http =
      let
        authelia_port = toString (mylib.getUriPort config.services.authelia.instances.main.settings.server.address);
      in
      {
        # Authelia's endpoint name correlates with the path of the endpoint, e.g., /api/authz/forward-auth for forward-auth
        # Ref: https://www.authelia.com/configuration/miscellaneous/server-endpoints-authz/#name
        middlewares.authelia-auth.forwardAuth.address = "http://127.0.0.1:${authelia_port}/api/authz/forward-auth?authelia_url=${(builtins.head config.services.authelia.instances.main.settings.session.cookies).authelia_url}/";
        # Router for the login portal
        routers.authelia = {
          rule = "Host(`auth.${const.domain}`)";
          entryPoints = [ "websecure" ];
          service = "authelia";
          tls = { };
        };
        services.authelia.loadBalancer = {
          servers = [ { url = "http://127.0.0.1:${authelia_port}"; } ];
          healthCheck.path = "/api/health";
        };
      };
  };
}

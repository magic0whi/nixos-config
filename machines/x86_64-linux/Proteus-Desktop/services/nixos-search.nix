{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
let
  certs_dir = "/var/lib/opensearch/config/certs";
  sec_cfg =
    let
      gen_empt_yml =
        n: type:
        pkgs.writers.writeYAML n {
          _meta = {
            inherit type;
            config_version = 2;
          };
        };
    in
    {
      "config.yml" = (
        pkgs.writers.writeYAML "config.yml" {
          _meta = {
            type = "config";
            config_version = 2;
          };
          config = {
            dynamic = {
              http.anonymous_auth_enabled = false;
              authc = {
                # For nixos-search
                basic_auth_domain = {
                  http_enabled = true;
                  transport_enabled = true;
                  order = 0;
                  http_authenticator = {
                    type = "basic";
                    challenge = false; # Allows unauthenticated requests to fall through to OIDC
                  };
                  authentication_backend.type = "internal";
                };
                # OIDC, https://docs.opensearch.org/latest/security/authentication-backends/openid-connect/
                openid_auth_domain = {
                  http_enabled = true;
                  transport_enabled = true;
                  order = 1;
                  http_authenticator = {
                    type = "openid";
                    challenge = true;
                    config = {
                      subject_key = "preferred_username";
                      roles_key = "groups";
                      openid_connect_url = "https://auth.${myvars.domain}/.well-known/openid-configuration";
                      frontend_url = "https://nixos-search.${myvars.domain}/backend";
                      client_id = "nixos-search";
                      client_secret = "@OIDC_CLIENT_SECRET@"; # Placeholder for `sd`
                    };
                  };
                  authentication_backend.type = "noop";
                };
              };
            };
          };
        }
      );

      "internal_users.yml" = pkgs.writers.writeYAML "internal_users.yml" {
        _meta = {
          type = "internalusers";
          config_version = 2;
        };
        # Define your internal HTTP Basic Auth user here
        aWVSALXpZv = {
          # mkpasswd -m bcrypt
          hash = "$2y$12$VstyWtAiIsDOOQJYhbgJju37W12oyOPRL7iI4XFUn.7WSGZ83d1JW";
          reserved = false;
        };
        flake-info = {
          hash = "$2b$05$Jf88fBHj.b3me96NjfKdCeoqnWpkX8UJ5HNEEJx6xfZA82j98vWkG";
          reserved = false;
        };
      };

      "roles.yml" = pkgs.writers.writeYAML "roles.yml" {
        _meta = {
          type = "roles";
          config_version = 2;
        };
        metrics = {
          reserved = false;
          hidden = false;
          index_permissions = [
            {
              index_patterns = [ "*" ];
              allowed_actions = [
                "indices:monitor/settings/get"
                "indices:monitor/stats"
                "indices:admin/aliases/get"
              ];
            }
          ];
          cluster_permissions = [
            "cluster:monitor/main"
            "cluster:monitor/state"
            "cluster:monitor/health"
          ];
          tenant_permissions = [ ];
        };
        flake-info = {
          reserved = false;
          hidden = false;
          index_permissions = [
            {
              index_patterns = [
                "nixos-*"
                "*-nixos-*"
                "latest-*"
              ];
              allowed_actions = [
                # Required for push
                "indices:data/read/*"
                # Required to index new documents
                "indices:data/write/*"
                # Required for ExistsStrategy::Recreate
                "indices:admin/create"
                "indices:admin/delete"
                "indices:admin/get" # Required for check_index (HEAD request)
                # Required for write_alias
                "indices:admin/aliases/get"
                "indices:admin/aliases/delete"
                "indices:admin/aliases/put"
              ];
            }
          ];
          cluster_permissions = [
            "cluster:monitor/main"
            "indices:data/write/bulk"
          ];
          tenant_permissions = [ ];
        };
        # proteus = {
        #   reserved = false;
        #   hidden = false;
        #   index_permissions = [
        #     {
        #       index_patterns = [ "proteus_*" ];
        #       allowed_actions = [ "*" ];
        #     }
        #   ];
        #   cluster_permissions = [
        #     "indices:data/write/bulk"
        #     "indices:data/read/scroll"
        #   ];
        #   tenant_permissions = [ ];
        # };
      };

      # Assign users to roles
      "roles_mapping.yml" = pkgs.writers.writeYAML "roles_mapping.yml" (
        {
          _meta = {
            config_version = 2;
            type = "rolesmapping";
          };
        }
        // (builtins.mapAttrs
          (name: users: {
            reserved = if name == "all_access" then true else false;
            hidden = false;
            backend_roles = [ ]; # If a user possesses any of the roles listed, they are granted the this role
            hosts = [ ];
            users = users;
            and_backend_roles = [ ]; # A user must possess ALL of the backend roles listed here to be granted this role.
          })
          {
            all_access = [ myvars.username ];
            metrics = [ "aWVSALXpZv" ];
            readall = [ "aWVSALXpZv" ];
            flake-info = [ "flake-info" ];
          }
        )
      );

      # Satisfy securityadmin.sh with remaining blanks
      "nodes_dn.yml" = gen_empt_yml "nodes_dn.yml" "nodesdn";
      "action_groups.yml" = gen_empt_yml "action_groups.yml" "actiongroups";
      "tenants.yml" = gen_empt_yml "tenants.yml" "tenants";
      "whitelist.yml" = gen_empt_yml "whitelist.yml" "whitelist";
    };
in
{

  sops.secrets.nixos-search_client_secret = {
    sopsFile = "${myvars.secretsDir}/${config.networking.hostName}.sops.yaml";
    restartUnits = [ "opensearch.service" ];
  };

  networking.firewall.allowedTCPPorts = [ config.services.opensearch.settings."http.port" ];

  environment.systemPackages = [ pkgs.opensearch-cli ];
  services.opensearch = {
    enable = true;
    # package = pkgs.opensearch.overrideAttrs (old: {
    #   postInstall = (old.postInstall or "") + ''
    #     # Nixpkgs removes opensearch-cli, breaking opensearch-keystore, replace the broken keystore script with a no-op
    #     # to prevent the NixOS preStart from crashing.
    #     cat <<EOF > $out/bin/opensearch-keystore
    #     #!${lib.getExe pkgs.bash}
    #     set -e -o pipefail

    #     OPENSEARCH_MAIN_CLASS=org.opensearch.tools.cli.keystore.KeyStoreCli \\
    #       OPENSEARCH_ADDITIONAL_CLASSPATH_DIRECTORIES=lib/tools/keystore-cli \\
    #       ${lib.getExe pkgs.opensearch-cli} \\
    #       "\$@"
    #     EOF
    #     chmod +x $out/bin/opensearch-keystore
    #   '';
    # });
    settings = {
      "network.host" = "127.0.0.1";
      "http.cors.enabled" = "true";
      "http.cors.allow-origin" = "https://nixos-search.${myvars.domain}";
      "http.cors.allow-credentials" = "true";
      "http.cors.allow-headers" = "X-Requested-With,X-Auth-Token,Content-Type,Content-Length,Authorization";

      "plugins.security.disabled" = false;
      # OpenSearch reads cert's DN back formatted according to RFC 2253
      "plugins.security.authcz.admin_dn" = [ "C=CN,O=proteus,CN=opensearch" ];

      # Mandatory TLS for internal transport
      # Traefik handles TLS, but I cannot disable it as securityadmin.sh reports "Unrecognized SSL message, plaintext
      # connection?" and exit
      "plugins.security.ssl.http.enabled" = true;
      "plugins.security.ssl.http.pemkey_filepath" = "${certs_dir}/opensearch.key";
      "plugins.security.ssl.http.pemcert_filepath" = "${certs_dir}/opensearch.crt";
      "plugins.security.ssl.http.pemtrustedcas_filepath" = "${certs_dir}/opensearch.crt";
      "plugins.security.ssl.transport.enabled" = true;
      "plugins.security.ssl.transport.pemkey_filepath" = "${certs_dir}/opensearch.key";
      "plugins.security.ssl.transport.pemcert_filepath" = "${certs_dir}/opensearch.crt";
      # PEM file containing the root CA(s)
      "plugins.security.ssl.transport.pemtrustedcas_filepath" = "${certs_dir}/opensearch.crt";
      # "transport.ssl.enforce_hostname_verification" = false;
    };
  };
  services.caddy.virtualHosts."http://nixos-search.${myvars.domain}:${toString myvars.networking.caddyPort}" =
    let
      web_root = "${myvars.storagePath}/www";
    in
    {
      listenAddresses = [
        "127.0.0.1"
        "[::1]"
      ];
      extraConfig = ''
        root * ${web_root}/nixos-search
        file_server
        # https://caddyserver.com/docs/caddyfile/patterns#single-page-apps-spas
        try_files {path} /index.html
        encode
      '';
    };

  services.traefik.dynamicConfigOptions.http = {
    middlewares.strip-backend-prefix.stripPrefix.prefixes = [ "/backend" ];
    routers.nixos-search_backend = {
      rule = "Host(`nixos-search.${myvars.domain}`) && PathPrefix(`/backend`)";
      entryPoints = [ "websecure" ];
      middlewares = [ "strip-backend-prefix" ];
      service = "nixos-search_backend";
      tls = { };
      priority = 100; # Higher has greater proirity
    };
    serversTransports.ignorecert.insecureSkipVerify = true;
    services.nixos-search_backend.loadBalancer = {
      serversTransport = "ignorecert";
      servers = [ { url = "https://127.0.0.1:${toString config.services.opensearch.settings."http.port"}"; } ];
    };
  };

  systemd.services.opensearch =
    let
      cfg = config.services.opensearch;
    in
    {
      serviceConfig = {
        RuntimeDirectory = "opensearch";
        RuntimeDirectoryMode = "0700";
        LoadCredential = "nixos-search_client_secret:${config.sops.secrets.nixos-search_client_secret.path}";
      };
      preStart = lib.mkBefore ''
        if [ ! -d "${certs_dir}" ]; then
          echo "Generating mandatory internal Transport TLS certificates..."
          mkdir -p "${certs_dir}"

          ${lib.getExe pkgs.openssl} req -x509 -newkey rsa:2048 -keyout ${
            cfg.settings."plugins.security.ssl.transport.pemkey_filepath"
          } -out ${cfg.settings."plugins.security.ssl.transport.pemcert_filepath"} -sha256 -days 3650 -nodes -subj '/${
            builtins.concatStringsSep "/" (
              lib.reverseList (lib.splitString "," (builtins.head cfg.settings."plugins.security.authcz.admin_dn"))
            )
          }' \
            -addext "subjectAltName=IP:127.0.0.1,DNS:localhost,DNS:nixos-search.${myvars.domain}"

          chown -R opensearch:opensearch "${certs_dir}"
          chmod 600 "${certs_dir}"/*
        fi
      '';
      # Override the default HTTP plain wait script, avoids the deadlock where OpenSearch would never finish
      # starting when SSL enabled
      serviceConfig.ExecStartPost = lib.mkForce [
        (pkgs.writeShellScript "opensearch-setup-security" ''
          echo "Injecting OIDC secrets and applying OpenSearch security config..."

          ${lib.concatLines (lib.mapAttrsToList (filename: drv: "cp ${drv} $RUNTIME_DIRECTORY/${filename}") sec_cfg)}
          # `cp` preserves the permission from /nix/store
          chmod 600 "$RUNTIME_DIRECTORY/config.yml"

          SECRET_VAL=$(cat $CREDENTIALS_DIRECTORY/nixos-search_client_secret)
          cat "$RUNTIME_DIRECTORY/config.yml" | ${pkgs.sd}/bin/sd "@OIDC_CLIENT_SECRET@" "$SECRET_VAL" | ${lib.getExe' pkgs.moreutils "sponge"} "$RUNTIME_DIRECTORY/config.yml"

          # Wait for yellow status, I dropped the `-f` so 401 also treated as success
          while ! ${lib.getExe pkgs.curl} -sS --cacert ${cfg.settings."plugins.security.ssl.transport.pemcert_filepath"} \
            https://${cfg.settings."network.host"}:${toString cfg.settings."http.port"} 2>/dev/null; do
            sleep 1
          done

          # Apply the configuration to the OpenSearch index
          export JAVA_HOME="${pkgs.jdk21_headless}"
          ${lib.getExe pkgs.bash} ${config.services.opensearch.package}/plugins/opensearch-security/tools/securityadmin.sh \
            -cacert ${cfg.settings."plugins.security.ssl.transport.pemcert_filepath"} \
            -cert ${cfg.settings."plugins.security.ssl.transport.pemcert_filepath"} \
            -key ${cfg.settings."plugins.security.ssl.transport.pemkey_filepath"} \
            -cd "$RUNTIME_DIRECTORY" \
            -icl \
            -h ${config.services.opensearch.settings."network.host"} \
            -p ${toString config.services.opensearch.settings."http.port"}
        '')
      ];
    };
}

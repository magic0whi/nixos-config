{
  config,
  myvars,
  pkgs,
  lib,
  ...
}:
let
  nextcloud_port = 8080;
  restartUnits = [
    "nextcloud-setup.service"
    "nextcloud-cron.service"
    "nextcloud-update-plugins.service"
    "nextcloud-update-db.service"
    "phpfpm-nextcloud.service"
  ];
in
{
  sops.secrets =
    let
      sopsFile = "${myvars.secrets_dir}/${config.networking.hostName}.sops.yaml";
    in
    {
      nextcloud_db_password = { inherit sopsFile restartUnits; };
      nextcloud_admin_password = { inherit sopsFile restartUnits; };
      nextcloud_oidc_client_secret = { inherit sopsFile restartUnits; };
    };
  systemd.services =
    let
      clean_units = map (s: lib.removeSuffix ".service" s) restartUnits;
    in
    lib.mkMerge [
      # Add RequiresMountsFor to wait for storage mounted
      (lib.genAttrs clean_units (_: {
        unitConfig.RequiresMountsFor = [ myvars.storage_path ];
      }))
      # https://wiki.nixos.org/wiki/Nextcloud#Dynamic_configuration
      {
        nextcloud-custom-config = {
          after = [ "nextcloud-setup.service" ];
          wantedBy = [ "multi-user.target" ];
          path = [
            config.services.nextcloud.occ
            pkgs.jq
          ];
          script = ''
            nextcloud-occ app:disable app_api # I don't plan to run external AI apps
            # Logreader only supports "file" log_type and complains it, I'd rather prefer journald
            nextcloud-occ app:disable logreader
            nextcloud-occ app:disable twofactor_totp # Since we use Authelia OIDC
            nextcloud-occ app:disable federation # I don't share files with users on other Nextcloud instances
            nextcloud-occ app:disable circles # Teams
            nextcloud-occ app:disable user_status # Allows users to set a status message (e.g., "In a meeting", "Away")
            nextcloud-occ app:disable dashboard
            nextcloud-occ app:disable photos # I use immich instead

            nextcloud-occ app:enable files_external # Enable External Storage to mount Syncthing shared folders
            # Define the list of Syncthing folders to mount
            declare -A external_mounts=(
              [KeePassXC]="${myvars.storage_path}/share/Secrets/KeePassXC"
            )
            for mount_point in "''${!external_mounts[@]}"; do
              # Ensure the external mount doesn't duplicate mountpoints
              if ! nextcloud-occ files_external:list --output=json | jq -e --arg mp "/$mount_point" '.[] | select(.mount_point == $mp)' > /dev/null; then
                echo "Creating Syncthing external mount for $mount_point..."
                MOUNT_ID=$(nextcloud-occ files_external:create \
                  "$mount_point" \
                  'local' \
                  'null::null' \
                  -c datadir="''${external_mounts[$mount_point]}" \
                  --output=json)
                # Check filesystem changes: Always
                # nextcloud-occ files_external:option -n "$MOUNT_ID" filesystem_check_changes 2
                nextcloud-occ files_external:option -n "$MOUNT_ID" readonly 1
                # Grant access to all users, or use --add-user=username for specific users or --add-group=groupname
                nextcloud-occ files_external:applicable --add-user=proteus "$MOUNT_ID"
              fi
            done
          '';
        };
      }
    ];

  services.nextcloud = {
    enable = true;
    # package = pkgs.nextcloud33;
    hostName = "nextcloud.${myvars.domain}";
    # https = true;

    # home = "/srv/nextcloud";
    datadir = "${myvars.storage_path}/nextcloud";

    config = {
      dbtype = "pgsql";
      dbhost = "postgresql.${myvars.domain}";
      dbpassFile = config.sops.secrets.nextcloud_db_password.path;
      adminpassFile = config.sops.secrets.nextcloud_admin_password.path;
    };
    maxUploadSize = "20G";

    secrets.oidc_login_client_secret = config.sops.secrets.nextcloud_oidc_client_secret.path;
    settings = {
      serverid = "0";
      trusted_proxies = [
        "127.0.0.1"
        "::1"
      ];
      overwriteprotocol = "https";

      maintenance_window_start = 18;

      default_phone_region = "GB";

      allow_user_to_change_display_name = false;
      lost_password_link = "disabled";

      oidc_login_provider_url = "https://auth.${myvars.domain}"; # all other URLs are auto-discovered from .well-known
      oidc_login_client_id = "nextcloud";
      oidc_login_auto_redirect = true;
      oidc_login_logout_url = "https://auth.${myvars.domain}/logout"; # Redirect to this page after logging out the user
      oidc_login_end_session_redirect = false; # User will be redirected to the `oidc_login_logout_url` after logout
      oidc_login_button_text = "Log in with Authelia";
      oidc_login_hide_password_form = true;
      oidc_login_use_id_token = false; # Use ID Token instead of UserInfo

      # TIP: To get OIDC claims and attributes from Authelia:
      # sudo AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD="$(sudo cat /run/secrets/authelia_ldap_password)" \
      #   nix run --impure nixpkgs#authelia -- debug oidc claims proteus \
      #     --policy nextcloud_userinfo \
      #     --scopes "openid,profile,email,groups,nextcloud_userinfo" \
      #     --client-id nextcloud \
      #     -c $(systemctl cat authelia-main.service | grep -oP '(?<=--config )/nix/store/[^ ]+-config\.yml')
      # Or use flake generated setting (`nom build ".#nixosConfigurations.Proteus-NUC.config.system.build.toplevel"`):
      #     -c $(nix eval --raw ".#nixosConfigurations.Proteus-NUC.config.systemd.services.authelia-main.serviceConfig.ExecStart" | grep -oP '(?<=--config )/nix/store/[^ ]+-config\.yml')
      oidc_login_attributes = {
        id = "preferred_username";
        name = "name";
        mail = "email";
        groups = "groups";
        # home = "homeDirectory"; # Requires custom configuration inside Authelia
        is_admin = "is_nextcloud_admin";
      };

      oidc_login_default_group = "oidc"; # Default group to add users to
      # Use external storage instead of a symlink to the home directory. Requires the files_external app to be enabled
      # oidc_login_use_external_storage = true;
      oidc_login_scope = "openid profile email groups nextcloud_userinfo";
      oidc_login_disable_registration = false;
      oidc_login_redir_fallback = false; # Fallback to direct login if login from OIDC fails
      oidc_create_groups = true;
      oidc_login_webdav_enabled = false;
      # Enable authentication with user/password for DAV clients that do not support token authentication
      oidc_login_password_authentication = false;
      oidc_login_update_avatar = false;
      oidc_login_code_challenge_method = "S256"; # Enable PKCE flow for enhanced security
    };
    phpOptions."opcache.interned_strings_buffer" = "23";

    extraApps = { inherit (pkgs.nextcloud33Packages.apps) oidc_login; };
  };
  # Let Traefik own :80/:443, and move the generated Nextcloud nginx vhost to loopback.
  services.nginx.virtualHosts."${config.services.nextcloud.hostName}".listen = [
    {
      addr = "127.0.0.1";
      port = nextcloud_port;
    }
  ];

  services.traefik.dynamicConfigOptions.http = {
    # Strict-Transport-Security
    middlewares.nextcloud-hsts.headers = {
      stsSeconds = 15552000;
      stsIncludeSubdomains = true;
      stsPreload = true; # Adds preload flag to STS header
      forceSTSHeader = true; # Adds STS header for HTTP connections
    };
    routers.nextcloud = {
      rule = "Host(`nextcloud.${myvars.domain}`)";
      entryPoints = [ "websecure" ];
      middlewares = [ "nextcloud-hsts" ];
      service = "nextcloud";
      tls = { };
    };
    services.nextcloud.loadBalancer = {
      servers = [ { url = "http://127.0.0.1:${toString nextcloud_port}"; } ];
      healthCheck.path = "/status.php";
    };
  };
}

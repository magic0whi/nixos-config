{
  config,
  const,
  lib,
  machineConfigs,
  mySecrets,
  mylib,
  pkgs,
  ...
}:
let
  hostname = config.networking.hostName;
  hostname_psql = const.networking.findFirstHostBySubdomain "psql";

  # Garage S3 external storage, backed by the `nextcloud` bucket on the cloud Garage cluster
  # NOTE: any cluster node serves the whole cluster, so the first node is picked as the endpoint
  hostname_s3 = "Proteus-NixOS-0";
  machine_cfg_s3 = machineConfigs.${hostname_s3}.config;
  s3_bucket = "nextcloud";
  s3_endpoint_host = "${hostname_s3}.s3.${const.domain}";
  # sing-box occupies :443 on cloud nodes, Traefik websecure listens on :8443
  s3_endpoint_port = mylib.getUriPort machine_cfg_s3.services.traefik.staticConfigOptions.entryPoints.websecure.address;
  s3_region = machine_cfg_s3.services.garage.settings.s3_api.s3_region;

  nextcloud_port = 8081;

  nextcloud_units = [
    "nextcloud-setup.service"
    "nextcloud-cron.service"
    "nextcloud-update-plugins.service"
    "nextcloud-update-db.service"
    "phpfpm-nextcloud.service"
  ];

  cfg = config.services.nextcloud;
in
{
  vars.hostAddrs.${hostname}.easytier.subdomains =
    let
      subs = [ "nextcloud" ];
    in
    {
      A = subs;
      AAAA = subs;
    };
  sops.secrets =
    let
      sopsFile = mySecrets + "/${hostname}/nextcloud.sops.yaml";
    in
    {
      nextcloud_db_password = {
        inherit sopsFile;
        restartUnits = nextcloud_units;
      };
      nextcloud_client_secret = {
        inherit sopsFile;
        restartUnits = nextcloud_units;
      };
      nextcloud_s3_access_key = {
        inherit sopsFile;
        # NOTE: owned by nextcloud because `nextcloud-occ` runs PHP as the nextcloud user,
        # and `files_external:config --value-from-file` reads the file from PHP
        owner = "nextcloud";
        # Re-run the mount setup script to sync rotated credentials into Nextcloud
        restartUnits = [ "nextcloud-custom-config.service" ];
      };
      nextcloud_s3_secret_key = {
        inherit sopsFile;
        owner = "nextcloud";
        restartUnits = [ "nextcloud-custom-config.service" ];
      };
    };
  systemd.services = lib.mkMerge [
    (
      let
        clean_units = map (s: lib.removeSuffix ".service" s) nextcloud_units;
      in
      lib.genAttrs clean_units (_: {
        # Add RequiresMountsFor to wait for storage mounted
        unitConfig.RequiresMountsFor = [ const.storagePath ];
        wants = [ "ldap-online.service" ];
        after = [ "ldap-online.service" ];
      })
    )

    # https://wiki.nixos.org/wiki/Nextcloud#Dynamic_configuration
    {
      nextcloud-custom-config = {
        after = [ "nextcloud-setup.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [
          cfg.occ
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
          nextcloud-occ app:disable updatenotification

          nextcloud-occ app:enable files_external # Enable External Storage to mount Syncthing shared folders and Garage S3
          # Define the list of Syncthing folders to mount
          declare -A external_mounts=(
            [KeePassXC]="${const.storagePath}/share/KeePassXC"
            [Aria2 Downloads]="${const.storage2Path}/aria2"
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

          # Garage S3 (bucket `${s3_bucket}`) on the cloud Garage cluster
          S3_MOUNT_POINT="Garage S3"
          S3_MOUNT_ID=$(nextcloud-occ files_external:list --output=json | jq -r --arg mp "/$S3_MOUNT_POINT" '.[] | select(.mount_point == $mp) | .mount_id')
          if [ -n "$S3_MOUNT_ID" ] && [ "$S3_MOUNT_ID" != "null" ]; then
            echo "Garage S3 external mount exists (id: $S3_MOUNT_ID), syncing credentials..."
          else
            echo "Creating Garage S3 external mount..."
            S3_MOUNT_ID=$(nextcloud-occ files_external:create \
              "$S3_MOUNT_POINT" \
              'amazons3' \
              'amazons3::accesskey' \
              -c bucket="${s3_bucket}" \
              -c hostname="${s3_endpoint_host}" \
              -c port="${toString s3_endpoint_port}" \
              -c region="${s3_region}" \
              -c use_ssl=true \
              -c use_path_style=true \
              --applicable-user=proteus \
              --output=json)
          fi
          # Sync credentials from the sops secrets on every run, so rotating the Garage key only requires updating the sops file
          nextcloud-occ files_external:config "$S3_MOUNT_ID" key ${config.sops.secrets.nextcloud_s3_access_key.path} --value-from-file
          nextcloud-occ files_external:config "$S3_MOUNT_ID" secret ${config.sops.secrets.nextcloud_s3_secret_key.path} --value-from-file
        '';
      };
    }
  ];

  # NOTE: use datadir on another storage device would causes override.config.php being GCed
  # Ref: https://github.com/NixOS/nixpkgs/issues/356973#issuecomment-3086117184
  fileSystems."/var/lib/nextcloud" = {
    device = "${const.storagePath}/nextcloud";
    options = [ "bind" ];
    fsType = "auto";
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud35;
    hostName = "nextcloud.${const.domain}";
    # https = true;

    # home = "/srv/nextcloud";

    # NOTE: use datadir on another storage device would causes override.config.php being GCed
    # Ref: https://github.com/NixOS/nixpkgs/issues/356973#issuecomment-3086117184
    # datadir = "${const.storagePath}/nextcloud";

    config = {
      dbtype = "pgsql";
      dbhost = if hostname == hostname_psql then "/run/postgresql" else "psql.${const.domain}";
      dbpassFile = config.sops.secrets.nextcloud_db_password.path;
    };
    maxUploadSize = "20G";

    secrets.oidc_login_client_secret = config.sops.secrets.nextcloud_client_secret.path;
    settings = {
      serverid = "0";
      trusted_proxies = [
        "127.0.0.1"
        "::1"
      ];
      overwriteprotocol = "https";

      maintenance_window_start = 18;

      default_phone_region = "CN";

      updatechecker = false;

      allow_user_to_change_display_name = false;
      lost_password_link = "disabled";

      oidc_login_provider_url = "https://auth.${const.domain}"; # all other URLs are auto-discovered from .well-known
      oidc_login_client_id = "nextcloud";
      oidc_login_auto_redirect = true;
      oidc_login_logout_url = "https://auth.${const.domain}/logout"; # Redirect to this page after logging out the user
      oidc_login_end_session_redirect = false; # User will be redirected to the `oidc_login_logout_url` after logout
      oidc_login_button_text = "Log in with Authelia";
      oidc_login_hide_password_form = true;
      oidc_login_use_id_token = false; # Use ID Token instead of UserInfo

      # TIP: To get OIDC claims and attributes from Authelia:
      # sudo AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD="$(sudo cat /run/secrets/authelia_ldap_bind_password)" \
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

    extraApps = { inherit (cfg.package.packages.apps) oidc_login; };
  };
  # Let Traefik own :80/:443, and move the generated Nextcloud nginx vhost to loopback.
  services.nginx.virtualHosts."${cfg.hostName}".listen = [
    {
      addr = "127.0.0.1";
      port = nextcloud_port;
    }
  ];

  users.users.nextcloud.extraGroups = [ "storage" ];
  services.phpfpm.pools.nextcloud.group = lib.mkForce "storage";

  services.traefik.dynamicConfigOptions.http = {
    # Strict-Transport-Security
    middlewares.nextcloud-hsts.headers = {
      stsSeconds = 15552000;
      stsIncludeSubdomains = true;
      stsPreload = true; # Adds preload flag to STS header
      forceSTSHeader = true; # Adds STS header for HTTP connections
    };
    routers.nextcloud = {
      rule = "Host(`nextcloud.${const.domain}`)";
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

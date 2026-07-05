{
  config,
  lib,
  const,
  pkgs,
  mylib,
  ...
}:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "paperless" ];
        AAAA = [ "paperless" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  sops =
    let
      sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
      restartUnits = [
        "paperless-scheduler.service"
        "paperless-task-queue.service"
        "paperless-consumer.service"
        "paperless-web.service"
      ];
    in
    {
      secrets = {
        paperless_dbpass = { inherit sopsFile restartUnits; };
        paperless_admin_password = { inherit sopsFile restartUnits; };
        paperless_authelia_secret = { inherit sopsFile restartUnits; };
      };
      templates."paperless.env" = {
        inherit restartUnits;
        # Fixes `paperless-manage`
        # https://github.com/NixOS/nixpkgs/blob/15f4ee454b1dce334612fa6843b3e05cf546efab/nixos/modules/services/misc/paperless.nix#L53
        owner = config.services.paperless.user;
        content = mylib.toEnv {
          # paperless-manage use bash `souece` to import environments
          PAPERLESS_DBPASS = mylib.escapeStr config.sops.placeholder.paperless_dbpass;
          PAPERLESS_ADMIN_PASSWORD = mylib.escapeStr config.sops.placeholder.paperless_admin_password;
          PAPERLESS_SOCIALACCOUNT_PROVIDERS = mylib.escapeStr (
            builtins.toJSON {
              openid_connect.APPS = lib.singleton {
                client_id = "paperless";
                name = "Authelia";
                provider_id = "authelia";
                secret = config.sops.placeholder.paperless_authelia_secret;
                settings.server_url = "https://auth.${const.domain}/.well-known/openid-configuration";
              };
            }
          );
        };
      };
    };
  services.paperless = {
    domain = "paperless.${const.domain}";
    enable = true;
    settings = {
      PAPERLESS_DBENGINE = "postgresql";
      # PAPERLESS_DBHOST = "/run/postgresql"; # Unix socket
      PAPERLESS_DBHOST = "postgresql.${const.domain}";
      PAPERLESS_DBSSLMODE = "require";
      PAPERLESS_DBNAME = config.services.paperless.user;
      PAPERLESS_DBUSER = config.services.paperless.user;

      # https://tesseract-ocr.github.io/tessdoc/Data-Files-in-different-versions.html
      PAPERLESS_OCR_LANGUAGES = "chi-sim chi-tra";
      PAPERLESS_OCR_LANGUAGE = "chi_sim+chi_tra+eng";
      # https://dateparser.readthedocs.io/en/latest/supported_locales.html
      PAPERLESS_DATE_PARSER_LANGUAGES = "en+zh+zh-Hant";
      PAPERLESS_FILENAME_DATE_ORDER = "YMD"; # Check the document filename for date information

      PAPERLESS_ADMIN_USER = const.username;
      PAPERLESS_USE_X_FORWARD_HOST = true;
      PAPERLESS_USE_X_FORWARD_PORT = true;

      APERLESS_WEBSERVER_WORKERS = 16;
      PAPERLESS_WORKER_TIMEOUT = 300; # Default 1800 seconds (30min) is too long
      PAPERLESS_FILENAME_FORMAT = "{{ created_year }}/{{ correspondent }}/{{ document_type }}/{{ title }}";

      # Enable OIDC
      REQUESTS_CA_BUNDLE = config.security.pki.caBundle;
      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      # Optional flags to streamline the SSO experience
      PAPERLESS_SOCIALACCOUNT_AUTO_SIGNUP = true; # Automatically create users on first login
      PAPERLESS_DISABLE_REGULAR_LOGIN = true; # Disable Paperless' login
      PAPERLESS_REDIRECT_LOGIN_TO_SSO = true; # Auto-redirect to Authelia, bypassing the Paperless login screen
    };
    environmentFile = config.sops.templates."paperless.env".path;
    # dataDir = "/srv/paperless";

    exporter = {
      enable = true;
      onCalendar = const.backupTimes.paperless;
      directory = "/srv/Backups/paperless-export";
      settings.no-archive = true;
      settings.no-thumbnail = true;
    };
  };

  systemd.services =
    let
      cfg = config.services.paperless.exporter;
    in
    lib.mkIf cfg.enable {
      paperless-exporter.serviceConfig = {
        # Type=oneshot forces systemd to wait until the paperless-exporter-start script completely finishes (which
        # spawns python to export the PDFs to a temporary folder, then renames it to `cfg.exporter.directory` ). If this
        # is Type=simple (the default), systemd will run ExecStartPost instantly, before the PDFs are generated, causing
        # them to be owned by paperless:paperless.
        Group = "storage";
        Type = "oneshot";
        # As of 2026-05-01, paperless-export don't allow group to access
        ExecStartPost = [ "+${pkgs.coreutils}/bin/chmod -R g+r ${cfg.directory}" ];
      };
    };

  services.traefik.dynamicConfigOptions.http = {
    routers.paperless = {
      rule = "Host(`paperless.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "paperless";
      tls = { };
    };
    services.paperless.loadBalancer.servers = [ { url = "http://127.0.0.1:${toString config.services.paperless.port}"; } ];
  };
}

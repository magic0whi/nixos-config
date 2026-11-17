{
  config,
  lib,
  const,
  pkgs,
  mylib,
  ...
}:
let
  hostname = config.networking.hostName;
  hostname_psql = const.networking.findFirstHostBySubdomain "psql";
in
{
  vars.hostAddrs.${hostname}.easytier.subdomains =
    let
      subs = [ "paperless" ];
    in
    {
      A = subs;
      AAAA = subs;
    };
  sops =
    let
      sopsFile = "${const.secretsDir}/${hostname}.sops.yaml";
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
  # https://github.com/NixOS/nixpkgs/issues/582142
  nixpkgs.overlays = lib.singleton (
    _: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (_: pyprev: {
          ocrmypdf = pyprev.ocrmypdf.overrideAttrs (old: {
            disabledTests = (old.disabledTests or [ ]) ++ [ "test_validation_performance" ];
          });
        })
      ];

      # Tesseract "best" LSTM models instead of the nixpkgs default ("standard")
      # tessdata: better on dense CJK layouts, at the cost of slower OCR.
      # Upstream: https://github.com/tesseract-ocr/tessdata_best
      tesseract5 = prev.tesseract5.override {
        tessdata = prev.runCommand "tessdata-best" { } (
          ''
            mkdir -p $out
          ''
          + lib.concatStrings (
            lib.mapAttrsToList
              (lang: hash: ''
                ln -s ${
                  prev.fetchurl {
                    url = "https://raw.githubusercontent.com/tesseract-ocr/tessdata_best/e12c65a915945e4c28e237a9b52bc4a8f39a0cec/${lang}.traineddata";
                    inherit hash;
                  }
                } $out/${lang}.traineddata
              '')
              {
                eng = "sha256-goCu0Hgv4nJXpo6hD+fvMkyg+Nhb0v0UXRwrVgvLZro=";
                chi_sim = "sha256-T+8tEwbI6HYW1NPkxsZ/r11EvjNCKQz48vD246p+c1s=";
                chi_tra = "sha256-GqYEiFdMr6aUhtkZKE8HnKm2j8x/atjcH/GzGN/ZcCg=";
                # osd/equ are byte-identical to nixpkgs', but listing them keeps the
                # tessdata dir self-contained (osd is required for --rotate-pages).
                osd = "sha256-nPXVdvzEdWTxEmWEHlyoOQAefm84/396rPRtFalrAP8=";
                equ = "sha256-j2YDI9int6Do0vrho0OebkcCIr+7mQsqt/6eH7R5HAs=";
              }
          )
        );
      };
    }
  );
  services.paperless = {
    enable = true;
    group = "storage";
    domain = "paperless.${const.domain}";
    settings = {
      PAPERLESS_DBENGINE = "postgresql";
      # Unix socket if psql is on the same machines
      PAPERLESS_DBHOST = if hostname == hostname_psql then "/run/postgresql" else "psql.${const.domain}";
      PAPERLESS_DBSSLMODE = "require";
      PAPERLESS_DBNAME = config.services.paperless.user;
      PAPERLESS_DBUSER = config.services.paperless.user;

      PAPERLESS_ADMIN_USER = const.username;
      PAPERLESS_USE_X_FORWARD_HOST = true;
      PAPERLESS_USE_X_FORWARD_PORT = true;

      # Enable OIDC
      REQUESTS_CA_BUNDLE = config.security.pki.caBundle;
      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      # Optional flags to streamline the SSO experience
      PAPERLESS_SOCIALACCOUNT_AUTO_SIGNUP = true; # Automatically create users on first login
      PAPERLESS_DISABLE_REGULAR_LOGIN = true; # Disable Paperless' login
      PAPERLESS_REDIRECT_LOGIN_TO_SSO = true; # Auto-redirect to Authelia, bypassing the Paperless login screen

      # https://tesseract-ocr.github.io/tessdoc/Data-Files-in-different-versions.html
      PAPERLESS_OCR_LANGUAGE = "chi_sim+chi_tra+eng";
      # NOTE: PAPERLESS_OCR_LANGUAGES (download extra fonts) is docker-only, no-op here
      PAPERLESS_OCR_ROTATE_PAGES_THRESHOLD = 8; # default 12; phone photos under-rotate
      PAPERLESS_OCR_USER_ARGS.optimize = 1; # downsample 600 dpi pages in the archive

      # https://dateparser.readthedocs.io/en/latest/supported_locales.html
      PAPERLESS_DATE_PARSER_LANGUAGES = "en+zh+zh-Hant";
      PAPERLESS_FILENAME_DATE_ORDER = "MDY"; # Check the document filename for date information

      PAPERLESS_WEBSERVER_WORKERS = 4;
      PAPERLESS_WORKER_TIMEOUT = 600; # Default 1800 seconds (30min) is too long
      PAPERLESS_FILENAME_FORMAT = "{{ created_year }}/{{ correspondent }}/{{ document_type }}/{{ title }}";

      # Paperless-ngx 3.0 allows duplicate documents to be consumed by default except when this setting is enabled
      PAPERLESS_CONSUMER_DELETE_DUPLICATES = true;

      # TODO: evaluate remote OCR (Azure AI); needs a sops secret for the key:
      #   PAPERLESS_REMOTE_OCR_ENGINE = "azureai";
      #   PAPERLESS_REMOTE_OCR_API_KEY = <sops secret>;
      #   PAPERLESS_REMOTE_OCR_ENDPOINT = "https://<resource>.cognitiveservices.azure.com/";
      #   PAPERLESS_REMOTE_OCR_MODE = "workflow_only"; # opt in per workflow

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

{
  mySecrets,
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
      sopsFile = mySecrets + "/${hostname}/paperless.sops.yaml";
      restartUnits = [
        "paperless-scheduler.service"
        "paperless-task-queue.service"
        "paperless-consumer.service"
        "paperless-web.service"
      ];
    in
    {
      secrets = {
        paperless_db_password = { inherit sopsFile restartUnits; };
        paperless_admin_password = { inherit sopsFile restartUnits; };
        paperless_client_secret = { inherit sopsFile restartUnits; };
      };
      templates."paperless.env" = {
        inherit restartUnits;
        # Fixes `paperless-manage`
        # https://github.com/NixOS/nixpkgs/blob/15f4ee454b1dce334612fa6843b3e05cf546efab/nixos/modules/services/misc/paperless.nix#L53
        owner = config.services.paperless.user;
        content = mylib.toEnv {
          # paperless-manage use bash `souece` to import environments
          PAPERLESS_DBPASS = mylib.escapeStr config.sops.placeholder.paperless_db_password;
          PAPERLESS_ADMIN_PASSWORD = mylib.escapeStr config.sops.placeholder.paperless_admin_password;
          PAPERLESS_SOCIALACCOUNT_PROVIDERS = mylib.escapeStr (
            builtins.toJSON {
              openid_connect.APPS = lib.singleton {
                client_id = "paperless";
                name = "Authelia";
                provider_id = "authelia";
                secret = config.sops.placeholder.paperless_client_secret;
                settings.server_url = "https://auth.${const.domain}/.well-known/openid-configuration";
              };
            }
          );
        };
      };
    };
  # TODO: https://github.com/NixOS/nixpkgs/issues/582142
  nixpkgs.overlays = lib.singleton (
    _: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (_: pyprev: {
          ocrmypdf = pyprev.ocrmypdf.overrideAttrs (old: {
            disabledTests = (old.disabledTests or [ ]) ++ [ "test_validation_performance" ];
          });
        })
      ];
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

      # No mail accounts are configured, so don't schedule the default
      # every-10-minutes mail poll (it leaves a "Mail Fetch" task behind each run).
      # Remove this if mail fetching is ever set up.
      PAPERLESS_EMAIL_TASK_CRON = "disable";

      PAPERLESS_MAX_IMAGE_PIXELS = 400000000; # Default: 178,956,970 px
      PAPERLESS_OCR_MAX_IMAGE_PIXELS = 400000000;
    };
    environmentFile = config.sops.templates."paperless.env".path;
    # dataDir = "/srv/paperless";

    # Local OCR plugin: RapidOCR.
    # Takes photos/scans, including scans that already carry an old text layer
    # (it is replaced); born-digital PDFs and non-CJK scans stay on Tesseract.
    extraPythonPackages =
      ps:
      let
        p = ps.overrideScope (
          final: prev: {
            # They're not duplicates, the outer onnxruntime is a python wheel, insides are C++ libs
            onnxruntime = prev.onnxruntime.override {
              onnxruntime = pkgs.onnxruntime.override {
                cudaSupport = true;
                ncclSupport = false;
                tensorrtSupport = false;
              };
            };
            rapidocr-onnxruntime = prev.rapidocr-onnxruntime.override { onnxruntime = final.onnxruntime; };
          }
        );
      in
      [
        (pkgs.callPackage (mylib.relToRoot "pkgs/paperless-rapidocr") { pythonPackages = p; })
        p.numpy
        p.onnxruntime
        p.opencv-python
        p.pillow
        p.pyclipper
        p.pymupdf
        p.pyyaml
        p.rapidocr-onnxruntime
        p.shapely
        p.six
        p.tqdm
      ];

    exporter = {
      enable = true;
      onCalendar = const.backupTimes.paperless;
      directory = "/srv/Backups/paperless-export";
      settings.no-archive = true;
      settings.no-thumbnail = true;
    };
  };

  systemd.services = lib.mkMerge [
    (
      let
        cfg = config.services.paperless.exporter;
      in
      lib.mkIf cfg.enable {
        paperless-exporter.serviceConfig = {
          # Type=oneshot forces systemd to wait until the paperless-exporter-start
          # script completely finishes (which spawns python to export the PDFs
          # to a temporary folder, then renames it to `cfg.exporter.directory`).
          # If this is Type=simple (the default), systemd will run ExecStartPost
          # instantly, before the PDFs are generated, causing them to be owned
          # by paperless:paperless.
          Type = "oneshot";
          # As of 2026-05-01, paperless-export don't allow group to access
          ExecStartPost = [ "+${pkgs.coreutils}/bin/chmod -R g+r ${cfg.directory}" ];
        };
      }
    )

    (lib.genAttrs
      [
        "paperless-task-queue"
        "paperless-consumer"
      ]
      (_: {
        # The CUDA driver library (libcuda.so.1) is provided by /run/opengl-driver/lib,
        # which system services do not inherit from the session.
        environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
        serviceConfig = {
          # PrivateDevices replaces /dev with a minimal set; the real nodes
          # cannot be re-added by DeviceAllow, so it must stay off.
          PrivateDevices = lib.mkForce false;
          DevicePolicy = "closed";
          DeviceAllow = [
            "char-nvidia rw"
            "char-nvidiactl rw"
            "char-nvidia-modeset rw"
            "char-nvidia-uvm rw"
          ];
          # ProcSubset=pid hides /proc/cpuinfo, which makes ONNX Runtime's
          # cpuinfo_initialize() fail and disables CPU feature detection.
          ProcSubset = lib.mkForce "all";
        };
      })
    )
  ];

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

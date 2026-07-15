{
  const,
  config,
  mylib,
  lib,
  ...
}:
let
  app_release = "stable";
  mount_path = const.storagePath;
  path_prefix = "${mount_path}/plane";

  backend_volumes = [
    "${./plane_gitea_authelia.py}:/code/plane/authentication/provider/oauth/gitea.py"
    "${config.security.pki.caBundle}:/usr/local/share/ca-certificates/proteus_ca.crt:ro"
  ];

  pgdata = "/var/lib/postgresql/data";

  restart_units = with config.virtualisation.oci-containers.containers; {
    plane-web = "${plane-web.serviceName}.service";
    plane-space = "${plane-space.serviceName}.service";
    plane-admin = "${plane-admin.serviceName}.service";
    plane-live = "${plane-live.serviceName}.service";
    plane-api = "${plane-api.serviceName}.service";
    plane-worker = "${plane-worker.serviceName}.service";
    plane-beat-worker = "${plane-beat-worker.serviceName}.service";
    plane-migrator = "${plane-migrator.serviceName}.service";
    plane-db = "${plane-db.serviceName}.service";
    plane-redis = "${plane-redis.serviceName}.service";
    plane-mq = "${plane-mq.serviceName}.service";
    plane-minio = "${plane-minio.serviceName}.service";
    plane-proxy = "${plane-proxy.serviceName}.service";
  };
in
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "plane" ];
        AAAA = [ "plane" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };

  sops =
    let
      sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";

      backend_units = with restart_units; [
        plane-api
        plane-worker
        plane-beat-worker
        plane-migrator
      ];
    in
    {
      secrets = {
        # TIP: generate a random secret key using: openssl rand -hex 32
        plane_postgres_password = {
          inherit sopsFile;
          restartUnits = [ restart_units.plane-db ] ++ backend_units;
        };
        plane_rabbitmq_password = {
          inherit sopsFile;
          restartUnits = [ restart_units.plane-mq ] ++ backend_units;
        };
        plane_secret_key = {
          inherit sopsFile;
          restartUnits = backend_units;
        };
        plane_aws_secret_access_key = {
          inherit sopsFile;
          restartUnits = [ restart_units.plane-minio ] ++ backend_units;
        };
        plane_live_server_secret_key = {
          inherit sopsFile;
          restartUnits = [ restart_units.plane-live ] ++ backend_units;
        };
        plane_gitea_client_secret = {
          inherit sopsFile;
          restartUnits = backend_units;
        };
      };
      templates = {
        "plane-app.env" = {
          restartUnits = backend_units;
          content = mylib.toEnv {
            # For default values, Ref:
            # https://github.com/makeplane/plane/blob/1e8f3630c7697129b61eb57f2453f0bf09224920/apps/api/plane/settings/common.py
            WEB_URL = "https://plane.${const.domain}";
            CORS_ALLOWED_ORIGINS = "https://plane.${const.domain}";
            REQUESTS_CA_BUNDLE = "/usr/local/share/ca-certificates/proteus_ca.crt";
            NODE_EXTRA_CA_CERTS = "/usr/local/share/ca-certificates/proteus_ca.crt";
            # DEBUG = 1;
            GUNICORN_WORKERS = 5;

            # DB & Auth Secrets
            # Secret Key (Primary cryptographic key for the main backend application)
            SECRET_KEY = config.sops.placeholder.plane_secret_key;
            DATABASE_URL = "postgresql://plane:${config.sops.placeholder.plane_postgres_password}@plane-db/plane";
            AMQP_URL = "amqp://plane:${config.sops.placeholder.plane_rabbitmq_password}@plane-mq:5672/plane";

            # Live server environment variables (Shared auth key for real-time WebSocket architecture)
            LIVE_SERVER_SECRET_KEY = config.sops.placeholder.plane_live_server_secret_key;

            # Authelia SSO
            IS_GITEA_ENABLED = 1;
            GITEA_HOST = "https://auth.${const.domain}";
            GITEA_CLIENT_ID = "plane";
            GITEA_CLIENT_SECRET = config.sops.placeholder.plane_gitea_client_secret;
            ENABLE_GITEA_SYNC = 1;

            # S3 Configuration
            USE_MINIO = 1;
            MINIO_ENDPOINT_SSL = 0;
            AWS_SECRET_ACCESS_KEY = config.sops.placeholder.plane_aws_secret_access_key;
            AWS_S3_ENDPOINT_URL = "http://plane-minio:9000";
          };
        };
        "plane-minio.env" = {
          restartUnits = [ restart_units.plane-minio ];
          content = mylib.toEnv {
            MINIO_ROOT_USER = "access-key";
            MINIO_ROOT_PASSWORD = config.sops.placeholder.plane_aws_secret_access_key;
          };
        };
        "plane-proxy.env" = {
          restartUnits = [ restart_units.plane-proxy ] ++ backend_units;
          content = mylib.toEnv {
            APP_DOMAIN = "plane.${const.domain}";
            FILE_SIZE_LIMIT = 5242880;
            BUCKET_NAME = "uploads";
            SITE_ADDRESS = ":80";
          };
        };
        "plane-db.env" = {
          restartUnits = [ restart_units.plane-db ] ++ backend_units;
          content = mylib.toEnv {
            POSTGRES_USER = "plane";
            # NOTE: Changing POSTGRES_PASSWORD here or in secrets.env after the database
            # is already initialized will NOT update the existing database user's
            # password. You must manually run an SQL command:
            # docker exec -e PGPASSWORD=<old_pw> <container_name> psql -U plane -d plane -c "ALTER USER plane WITH PASSWORD '<new_pw>';"
            POSTGRES_PASSWORD = config.sops.placeholder.plane_postgres_password;
            POSTGRES_DB = "plane";
            PGDATA = pgdata;
          };
        };
        "plane-redis.env" = {
          restartUnits = [
            restart_units.plane-redis
            restart_units.plane-live
          ]
          ++ backend_units;
          content = mylib.toEnv { REDIS_URL = "redis://plane-redis:6379/"; };
        };
        "plane-mq.env" = {
          restartUnits = [ restart_units.plane-mq ];
          content = mylib.toEnv {
            RABBITMQ_DEFAULT_USER = "plane";
            RABBITMQ_DEFAULT_PASS = config.sops.placeholder.plane_rabbitmq_password;
            RABBITMQ_DEFAULT_VHOST = "plane";
          };
        };

        "plane-live.env" = {
          restartUnits = [ restart_units.plane-live ];
          content = mylib.toEnv {
            API_BASE_URL = "http://plane-api:8000";
            LIVE_SERVER_SECRET_KEY = config.sops.placeholder.plane_live_server_secret_key;
          };
        };
      };
    };

  virtualisation.oci-containers.containers = {
    plane-web = {
      image = "makeplane/plane-frontend:${app_release}";
      hostname = "web";
      dependsOn = [
        "plane-api"
        "plane-worker"
      ];
      extraOptions = [ "--network=plane" ];
    };

    plane-space = {
      image = "makeplane/plane-space:${app_release}";
      hostname = "space";
      dependsOn = [
        "plane-api"
        "plane-worker"
        "plane-web"
      ];
      extraOptions = [ "--network=plane" ];
    };

    plane-admin = {
      image = "makeplane/plane-admin:${app_release}";
      hostname = "admin";
      dependsOn = [
        "plane-api"
        "plane-web"
      ];
      extraOptions = [ "--network=plane" ];
    };

    plane-live = {
      image = "makeplane/plane-live:${app_release}";
      hostname = "live";
      environmentFiles = with config.sops; [
        templates."plane-live.env".path
        templates."plane-redis.env".path
      ];
      dependsOn = [
        "plane-api"
        "plane-web"
      ];
      extraOptions = [ "--network=plane" ];
    };

    plane-api = {
      image = "makeplane/plane-backend:${app_release}";
      hostname = "api";
      cmd = [ "./bin/docker-entrypoint-api.sh" ];
      environmentFiles = with config.sops; [
        templates."plane-app.env".path
        templates."plane-redis.env".path
        templates."plane-proxy.env".path
      ];
      volumes = [ "${path_prefix}/logs_api:/code/plane/logs" ] ++ backend_volumes;
      dependsOn = [
        "plane-db"
        "plane-redis"
        "plane-mq"
      ];
      extraOptions = [ "--network=plane" ];
    };

    plane-worker = {
      image = "makeplane/plane-backend:${app_release}";
      cmd = [ "./bin/docker-entrypoint-worker.sh" ];
      environmentFiles = with config.sops; [
        templates."plane-app.env".path
        templates."plane-redis.env".path
        templates."plane-proxy.env".path
      ];
      volumes = [ "${path_prefix}/logs_worker:/code/plane/logs" ] ++ backend_volumes;
      dependsOn = [
        "plane-api"
        "plane-db"
        "plane-redis"
        "plane-mq"
      ];
      extraOptions = [ "--network=plane" ];
    };

    plane-beat-worker = {
      image = "makeplane/plane-backend:${app_release}";
      cmd = [ "./bin/docker-entrypoint-beat.sh" ];
      environmentFiles = with config.sops; [
        templates."plane-app.env".path
        templates."plane-redis.env".path
        templates."plane-proxy.env".path
      ];
      volumes = [ "${path_prefix}/logs_beat-worker:/code/plane/logs" ] ++ backend_volumes;
      dependsOn = [
        "plane-api"
        "plane-db"
        "plane-redis"
        "plane-mq"
      ];
      extraOptions = [ "--network=plane" ];
    };

    plane-migrator = {
      image = "makeplane/plane-backend:${app_release}";
      cmd = [ "./bin/docker-entrypoint-migrator.sh" ];
      environmentFiles = with config.sops; [
        templates."plane-app.env".path
        templates."plane-redis.env".path
        templates."plane-proxy.env".path
      ];
      volumes = [ "${path_prefix}/logs_migrator:/code/plane/logs" ] ++ backend_volumes;
      dependsOn = [
        "plane-db"
        "plane-redis"
      ];
      extraOptions = [ "--network=plane" ];
    };

    # TODO: use host's postgresql, need merge db
    plane-db = {
      image = "postgres:15.7-alpine";
      cmd = [
        "postgres"
        "-c"
        "max_connections=1000"
      ];
      environmentFiles = [ config.sops.templates."plane-db.env".path ];
      volumes = [ "${path_prefix}/pgdata:${pgdata}" ];
      extraOptions = [ "--network=plane" ];
    };

    plane-redis = {
      image = "valkey/valkey:7.2.11-alpine";
      volumes = [ "${path_prefix}/redisdata:/data" ];
      extraOptions = [ "--network=plane" ];
    };

    plane-mq = {
      image = "rabbitmq:3.13.6-management-alpine";
      environmentFiles = [ config.sops.templates."plane-mq.env".path ];
      volumes = [ "${path_prefix}/rabbitmq_data:/var/lib/rabbitmq" ];
      extraOptions = [ "--network=plane" ];
    };

    # TODO use hosts garage
    plane-minio = {
      image = "minio/minio:latest";
      hostname = "plane-minio";
      cmd = [
        "server"
        "/export"
        "--console-address"
        ":9090"
      ];
      environmentFiles = [ config.sops.templates."plane-minio.env".path ];
      volumes = [ "${path_prefix}/uploads:/export" ];
      extraOptions = [ "--network=plane" ];
    };

    # If you remove it, you will have to expose 6 different containers to the host
    # and write multiple path-based routers (/api/*, /god-mode/*, /spaces/*,
    # /live/*, /${BUCKET_NAME}/*, etc.). Furthmore this will likely break whenever
    # Plane updates their internal paths.
    plane-proxy = {
      image = "makeplane/plane-proxy:${app_release}";
      environmentFiles = [ config.sops.templates."plane-proxy.env".path ];
      ports = [ "127.0.0.1:8082:80" ];
      volumes = [
        "${path_prefix}/proxy_config:/config"
        "${path_prefix}/proxy_data:/data"
      ];
      dependsOn = [
        "plane-web"
        "plane-api"
        "plane-space"
        "plane-admin"
        "plane-live"
      ];
      extraOptions = [ "--network=plane" ];
    };
  };

  systemd.services = lib.mkMerge (
    lib.singleton {
      docker-network-plane = {
        path = [ config.virtualisation.docker.package ];
        wantedBy = [ "multi-user.target" ];
        after = [
          "docker.service"
          "docker.socket"
        ];
        # Adding script to handle "network already exists" safely
        script = "docker network inspect plane >/dev/null 2>&1 || docker network create plane";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStop = "${config.virtualisation.docker.package}/bin/docker network rm plane";
        };
      };
    }
    ++ map (s: { ${lib.removeSuffix ".service" s}.unitConfig.RequiresMountsFor = mount_path; }) (
      lib.mapAttrsToList (_: v: v) restart_units
    )
  );

  services.traefik.dynamicConfigOptions.http = {
    routers.plane = {
      rule = "Host(`plane.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "plane";
      tls = { };
    };
    services.plane.loadBalancer.servers = [ { url = "http://127.0.0.1:8082"; } ];
  };
}

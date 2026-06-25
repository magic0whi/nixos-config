{
  const,
  config,
  lib,
  ...
}:
let
  toEnv = lib.generators.toKeyValue { };

  app_release = "stable";
  plane_path = "${const.storagePath}/plane";

  common_volumes = [
    "${./plane_gitea_authelia.py}:/code/plane/authentication/provider/oauth/gitea.py"
    "${config.security.pki.caBundle}:/usr/local/share/ca-certificates/proteus_ca.crt:ro"
  ];
in
{
  sops =
    let
      sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
    in
    {
      secrets = {
        # TIP: generate a random secret key using: openssl rand -hex 32
        plane_postgres_password = { inherit sopsFile; };
        plane_rabbitmq_password = { inherit sopsFile; };
        plane_secret_key = { inherit sopsFile; };
        plane_aws_secret_access_key = { inherit sopsFile; };
        plane_live_server_secret_key = { inherit sopsFile; };
        plane_gitea_client_secret = { inherit sopsFile; };
      };
      templates = {
        "plane-app.env" = {
          content = ''
            WEB_URL=https://plane.${const.domain}
            CORS_ALLOWED_ORIGINS=https://plane.${const.domain}
            REQUESTS_CA_BUNDLE=/usr/local/share/ca-certificates/proteus_ca.crt
            NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates/proteus_ca.crt
            API_KEY_RATE_LIMIT=60/minute
            AUTHENTICATION_RATE_LIMIT=10/minute
            DEBUG=0
            GUNICORN_WORKERS=1
            WEBHOOK_ALLOWED_IPS=
            WEBHOOK_ALLOWED_HOSTS=

            # DB & Auth Secrets
            # Secret Key (Primary cryptographic key for the main backend application)
            SECRET_KEY=${config.sops.placeholder.plane_secret_key}
            DATABASE_URL=postgresql://plane:${config.sops.placeholder.plane_postgres_password}@plane-db/plane
            AMQP_URL=amqp://plane:${config.sops.placeholder.plane_rabbitmq_password}@plane-mq:5672/plane
            # Live server environment variables (Shared auth key for real-time WebSocket architecture)
            LIVE_SERVER_SECRET_KEY=${config.sops.placeholder.plane_live_server_secret_key}

            # Authelia SSO
            IS_GITEA_ENABLED=1
            GITEA_HOST=https://auth.${const.domain}
            GITEA_CLIENT_ID=plane
            GITEA_CLIENT_SECRET=${config.sops.placeholder.plane_gitea_client_secret}
            ENABLE_GITEA_SYNC=1

            # S3 Configuration
            USE_MINIO=1
            MINIO_ENDPOINT_SSL=0
            AWS_REGION=
            AWS_ACCESS_KEY_ID=access-key
            AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.plane_aws_secret_access_key}
            AWS_S3_ENDPOINT_URL=http://plane-minio:9000
            AWS_S3_BUCKET_NAME=uploads
          '';
        };
        "plane-minio.env" = {
          content = ''
            MINIO_ROOT_USER=access-key
            MINIO_ROOT_PASSWORD=${config.sops.placeholder.plane_aws_secret_access_key}
          '';
        };
        "plane-proxy.env" = {
          content = ''
            # Proxy Configuration (proxy-env)
            APP_DOMAIN=plane.${const.domain}
            FILE_SIZE_LIMIT=5242880
            # If SSL Cert to be generated, set CERT_EMAIl="email <EMAIL_ADDRESS>"
            CERT_EMAIL=
            CERT_ACME_CA=https://acme-v02.api.letsencrypt.org/directory
            # For DNS Challenge based certificate generation, set the CERT_ACME_DNS, CERT_EMAIL
            # CERT_ACME_DNS="acme_dns <CERT_DNS_PROVIDER> <CERT_DNS_PROVIDER_API_KEY>"
            BUCKET_NAME=uploads
            SITE_ADDRESS=:80
            TRUSTED_PROXIES=0.0.0.0/0
          '';
        };
        "plane-db.env" = {
          content = ''
            POSTGRES_USER=plane
            # NOTE: Changing POSTGRES_PASSWORD here or in secrets.env after the database
            # is already initialized will NOT update the existing database user's
            # password. You must manually run an SQL command:
            # docker exec -e PGPASSWORD=<old_pw> <container_name> psql -U plane -d plane -c "ALTER USER plane WITH PASSWORD '<new_pw>';"
            POSTGRES_PASSWORD=${config.sops.placeholder.plane_postgres_password}
            POSTGRES_DB=plane
            POSTGRES_PORT=5432
            PGDATA=/var/lib/postgresql/data
          '';
        };
        "plane-redis.env" = {
          content = toEnv { REDIS_URL = "redis://plane-redis:6379/"; };
        };
        "plane-mq.env" = {
          content = toEnv {
            RABBITMQ_DEFAULT_USER = "plane";
            RABBITMQ_DEFAULT_PASS = config.sops.placeholder.plane_rabbitmq_password;
            RABBITMQ_DEFAULT_VHOST = "plane";
          };
        };

        "plane-live.env" = {
          content = toEnv {
            API_BASE_URL = "http://plane-api:8000";
            LIVE_SERVER_SECRET_KEY = "${config.sops.placeholder.plane_live_server_secret_key}";
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
      volumes = [ "${plane_path}/logs_api:/code/plane/logs" ] ++ common_volumes;
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
      volumes = [ "${plane_path}/logs_worker:/code/plane/logs" ] ++ common_volumes;
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
      volumes = [ "${plane_path}/logs_beat-worker:/code/plane/logs" ] ++ common_volumes;
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
      volumes = [ "${plane_path}/logs_migrator:/code/plane/logs" ] ++ common_volumes;
      dependsOn = [
        "plane-db"
        "plane-redis"
      ];
      extraOptions = [ "--network=plane" ];
    };

    # TODO: use host's postgresql
    plane-db = {
      image = "postgres:15.7-alpine";
      cmd = [
        "postgres"
        "-c"
        "max_connections=1000"
      ];
      environmentFiles = [ config.sops.templates."plane-db.env".path ];
      volumes = [ "${plane_path}/pgdata:/var/lib/postgresql/data" ];
      extraOptions = [ "--network=plane" ];
    };

    plane-redis = {
      image = "valkey/valkey:7.2.11-alpine";
      volumes = [ "${plane_path}/redisdata:/data" ];
      extraOptions = [ "--network=plane" ];
    };

    plane-mq = {
      image = "rabbitmq:3.13.6-management-alpine";
      environmentFiles = [ config.sops.templates."plane-mq.env".path ];
      volumes = [ "${plane_path}/rabbitmq_data:/var/lib/rabbitmq" ];
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
      volumes = [ "${plane_path}/uploads:/export" ];
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
        "${plane_path}/proxy_config:/config"
        "${plane_path}/proxy_data:/data"
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

  systemd.services.docker-network-plane = {
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

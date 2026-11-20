# Self-hosted Firecrawl API, so MCP clients can scrape services that Firecrawl Cloud cannot reach
#
# Ref: https://github.com/firecrawl/firecrawl/blob/v2.11.744/docker-compose.yaml
# Ref: https://docs.firecrawl.dev/contributing/self-host
#
# NOTE: This uses Firecrawl's own `nuq-postgres` image, which ships pg_cron and the nuq queue schema pre-initialized.
{
  config,
  const,
  lib,
  mylib,
  ...
}:
let
  hostname = config.networking.hostName;
  mount_path = "${const.storagePath}/firecrawl";
  network = "firecrawl";
  api_port = toString 3002;

  containers = config.virtualisation.oci-containers.containers;

  dep_svcs = [
    containers.firecrawl-playwright.serviceName
    containers.firecrawl-postgres.serviceName
    containers.firecrawl-rabbitmq.serviceName
    containers.firecrawl-redis.serviceName
  ];

  shared_cfgs = {
    environment = {
      ALLOW_LOCAL_WEBHOOKS = "true"; # Allow scraping internal/private addresses and trusting the self-signed
      NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
      # Cannot use NODE_USE_SYSTEM_CA=1, in that container there is no /etc/ssl at all
    };
    volumes = [ "${config.security.pki.caBundle}:/etc/ssl/certs/ca-certificates.crt:ro" ];
  };
in
{
  vars.forwardAuthServices = [ "firecrawl" ];

  vars.hostAddrs.${hostname}.easytier.subdomains = {
    A = [ "firecrawl" ];
    AAAA = [ "firecrawl" ];
  };

  sops =
    let
      sopsFile = const.secretsDir + "/services/firecrawl.sops.yaml";
      postgres_units = [
        "${containers.firecrawl-api.serviceName}.service"
        "${containers.firecrawl-postgres.serviceName}.service"
      ];
    in
    {
      secrets.firecrawl_postgres_password = {
        inherit sopsFile;
        restartUnits = postgres_units;
      };
      templates."firecrawl.env" = {
        restartUnits = postgres_units;
        content = mylib.toEnv { POSTGRES_PASSWORD = config.sops.placeholder.firecrawl_postgres_password; };
      };
    };

  virtualisation.oci-containers.containers = {
    firecrawl-api = lib.mkMerge [
      shared_cfgs
      {
        image = "ghcr.io/firecrawl/firecrawl:2.11.744";
        cmd = [
          "node"
          "dist/src/harness.js"
          "--start-docker"
        ];
        ports = [ "127.0.0.1:${api_port}:${api_port}" ];
        environmentFiles = [ config.sops.templates."firecrawl.env".path ];
        environment = {
          HOST = "0.0.0.0";
          PORT = api_port;
          EXTRACT_WORKER_PORT = "3004";
          WORKER_PORT = "3005";
          HARNESS_STARTUP_TIMEOUT_MS = "60000";
          ENV = "local";

          REDIS_URL = "redis://firecrawl-redis:6379";
          REDIS_RATE_LIMIT_URL = "redis://firecrawl-redis:6379";
          PLAYWRIGHT_MICROSERVICE_URL = "http://firecrawl-playwright:3000/scrape";
          NUQ_RABBITMQ_URL = "amqp://firecrawl-rabbitmq:5672";

          POSTGRES_USER = "postgres";
          POSTGRES_DB = "postgres";
          POSTGRES_HOST = "firecrawl-postgres";
          POSTGRES_PORT = "5432";
          USE_DB_AUTHENTICATION = "false";

          # Firecrawl stops accepting jobs once host-wide usage passes these fractions.
          # Defaults are 0.8, and this host idles around 0.8, which stalled every worker.
          MAX_RAM = "0.95";
          MAX_CPU = "0.95";

          NUM_WORKERS_PER_QUEUE = "2";
          CRAWL_CONCURRENT_REQUESTS = "4";
          MAX_CONCURRENT_JOBS = "2";
          BROWSER_POOL_SIZE = "2";
        };
        dependsOn = map (lib.removePrefix "docker-") dep_svcs;
        extraOptions = [
          "--network=${network}"
          "--add-host=host.docker.internal:host-gateway"
          "--ulimit=nofile=65535:65535"
          "--cpus=3.0"
          "--memory=6g"
          "--memory-swap=6g"
        ];
      }
    ];

    firecrawl-playwright = lib.mkMerge [
      shared_cfgs
      {
        image = "ghcr.io/firecrawl/playwright-service@sha256:227ce3d8059173925a5a0697c63a1e947662cca934a609151651f578774edd5d";
        environment = {
          PORT = "3000";
          # BLOCK_MEDIA = "true"; # Block image metadata, screenshots, or media URLs from scrape
          MAX_CONCURRENT_PAGES = "4";
        };
        extraOptions = [
          "--network=${network}"
          "--add-host=host.docker.internal:host-gateway"
          "--security-opt=no-new-privileges"
          "--cap-drop=ALL"
          "--tmpfs=/tmp/.cache:noexec,nosuid,size=1g"
          "--cpus=1.5"
          "--memory=3g"
          "--memory-swap=3g"
        ];
      }
    ];

    firecrawl-postgres = {
      image = "ghcr.io/firecrawl/nuq-postgres@sha256:d719b36160eac2fcbe16dc7e7360ddb9c82c40ea5da183d07bf4a755c6a0b2ae";
      environmentFiles = [ config.sops.templates."firecrawl.env".path ];
      environment = {
        POSTGRES_USER = "postgres";
        POSTGRES_DB = "postgres";
      };
      volumes = [ "${mount_path}/postgres:/var/lib/postgresql/data" ];
      extraOptions = [
        "--network=${network}"
        "--health-cmd=pg_isready -U postgres -d postgres"
        "--health-interval=5s"
        "--health-timeout=5s"
        "--health-retries=5"
        "--health-start-period=5s"
      ];
    };

    firecrawl-redis = {
      image = "redis:7-alpine";
      cmd = [
        "redis-server"
        "--bind"
        "0.0.0.0"
      ];
      volumes = [ "${mount_path}/redis:/data" ];
      extraOptions = [ "--network=${network}" ];
    };

    firecrawl-rabbitmq = {
      image = "rabbitmq:3-management";
      volumes = [ "${mount_path}/rabbitmq:/var/lib/rabbitmq" ];
      extraOptions = [
        "--network=${network}"
        "--health-cmd=rabbitmq-diagnostics -q check_running"
        "--health-interval=5s"
        "--health-timeout=5s"
        "--health-retries=3"
        "--health-start-period=5s"
      ];
    };
  };

  systemd.services = lib.mkMerge (
    lib.singleton {
      "docker-network-${network}" = {
        path = [ config.virtualisation.docker.package ];
        wantedBy = [ "multi-user.target" ];
        after = [
          "docker.service"
          "docker.socket"
        ];
        script = "docker network inspect ${network} >/dev/null 2>&1 || docker network create ${network}";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStop = "${config.virtualisation.docker.package}/bin/docker network rm ${network}";
        };
      };
    }
    ++ map (name: { ${name}.unitConfig.RequiresMountsFor = mount_path; }) (
      dep_svcs ++ [ containers.firecrawl-api.serviceName ]
    )
  );

  services.traefik.dynamicConfigOptions.http = {
    routers.firecrawl = {
      rule = "Host(`firecrawl.${const.domain}`)";
      entryPoints = [ "websecure" ];
      middlewares = [ "authelia-auth" ];
      service = "firecrawl";
      tls = { };
    };
    services.firecrawl.loadBalancer.servers = [ { url = "http://127.0.0.1:${api_port}"; } ];
  };
}

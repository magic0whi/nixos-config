{
  config,
  const,
  ...
}:
let
  hostname = config.networking.hostName;
  hostname_psql = const.networking.findFirstHostBySubdomain "psql";
in
{
  vars.hostAddrs.${hostname}.easytier.subdomains = {
    A = [ "niks3" ];
    AAAA = [ "niks3" ];
  };
  sops =
    let
      restartUnits = [ "niks3.service" ];
      sopsFile = "${const.secretsDir}/common_hm.sops.yaml";
    in
    {
      secrets = {
        niks3_db_password = {
          sopsFile = "${const.secretsDir}/${hostname}.sops.yaml";
          inherit restartUnits;
        };
        aws_access_key = {
          inherit sopsFile restartUnits;
          owner = "niks3";
        };
        aws_secret_key = {
          inherit sopsFile restartUnits;
          owner = "niks3";
        };
        niks3_api_token = {
          sopsFile = "${const.secretsDir}/${hostname}.sops.yaml";
          owner = "niks3";
          inherit restartUnits;
        };
        "nix_secret.key" = {
          sopsFile = "${const.secretsDir}/nix_secret.key.sops";
          format = "binary";
          owner = "niks3";
          inherit restartUnits;
        };
      };
      templates.niks3_db_dsn = {
        # Unix socket if psql is on the same machines
        content =
          if hostname == hostname_psql then
            "postgres://niks3:${config.sops.placeholder.niks3_db_password}@/niks3"
          else
            "postgres://niks3:${config.sops.placeholder.niks3_db_password}@psql.${const.domain}/niks3?sslmode=require";
        owner = "niks3";
        inherit restartUnits;
      };
    };

  systemd.services.niks3.environment.NIKS3_DB_FILE = config.sops.templates.niks3_db_dsn.path;

  services.niks3 = {
    enable = true;
    httpAddr = "127.0.0.1:5751";

    database.connectionString = ""; # let niks3 read from NIKS3_DB_FILE. Default: "postgres:///niks3?user=niks3"
    s3 = {
      endpoint = "${hostname}.s3.${const.domain}";
      bucket = "nix-cache";
      region = config.services.garage.settings.s3_api.s3_region;
      useSSL = true;
      accessKeyFile = config.sops.secrets.aws_access_key.path;
      secretKeyFile = config.sops.secrets.aws_secret_key.path;
    };

    apiTokenFile = config.sops.secrets.niks3_api_token.path;

    # Signing keys for NAR signing
    signKeyFiles = [ config.sops.secrets."nix_secret.key".path ];

    # Used to generate landing page with usage instructions and public keys, which is uploaded to the S3 bucket.
    cacheUrl = "https://nix-cache.s3-pub.${const.domain}";

    oidc.providers.authelia = {
      issuer = "https://auth.${const.domain}";
      audience = "niks3";
      boundClaims.client_id = [ "niks3_yajuusexnpai" ];
      # We cannot modify to GitHub OIDC Subject Format:
      # identity_providers: oidc: claims_policies: niks3_git_info: custom_claims: claim with name 'sub' can't be used in a claims policy as it's a standard claim
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.niks3 = {
      rule = "Host(`niks3.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "niks3";
      tls = { };
    };
    services.niks3.loadBalancer.servers = [ { url = "http://${config.services.niks3.httpAddr}"; } ];
  };
}

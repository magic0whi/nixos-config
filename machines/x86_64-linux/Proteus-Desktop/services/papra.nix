{
  mylib,
  lib,
  const,
  config,
  ...
}:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "papra" ];
        AAAA = [ "papra" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  sops =
    let
      restartUnits = [ "${config.virtualisation.oci-containers.containers.papra.serviceName}.service" ];
      sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
    in
    {
      secrets = {
        papra_auth_secret = { inherit sopsFile restartUnits; };
        papra_oidc_client_secret = { inherit sopsFile restartUnits; };
      };
      templates."papra.env" = {
        inherit restartUnits;
        content = mylib.toEnv {
          AUTH_SECRET = config.sops.placeholder.papra_auth_secret;
          AUTH_PROVIDERS_CUSTOMS = builtins.toJSON (
            lib.singleton {
              providerId = "authelia";
              providerName = "Authelia";
              type = "oidc";
              discoveryUrl = "https://auth.${const.domain}/.well-known/openid-configuration";
              clientId = "papra";
              clientSecret = config.sops.placeholder.papra_oidc_client_secret;
              scopes = [
                "openid"
                "profile"
                "email"
              ];
              pkce = true;
            }
          );
        };
      };
    };
  virtualisation.oci-containers.containers.papra = {
    image = "ghcr.io/papra-hq/papra@sha256:feb8c6e03bbbd1a730bc606fe3fb5a0fe13a71edb4f7d44b7f8f6940cca76a3a";
    # autoStart = false; # equivalent to 'restart: unless-stopped', default true
    ports = [ "127.0.0.1:1221:1221" ];
    environmentFiles = [ config.sops.templates."papra.env".path ];

    # Environment variables must be strings in Nix
    environment = {
      APP_BASE_URL = "https://papra.${const.domain}";
      # NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/proteus_ca.pub.pem";
      NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
      DOCUMENTS_OCR_LANGUAGES = "chi_sim,chi_tra,eng";
      MAX_ORGANIZATION_COUNT_PER_USER = "40";
      DOCUMENT_STORAGE_MAX_UPLOAD_SIZE = "104857600";
    };

    volumes = [
      "${const.storagePath}/papra:/app/app-data"
      # "${const.secretsDir}/proteus_ca.pub.pem:/etc/ssl/certs/proteus_ca.pub.pem:ro"
      "${config.security.pki.caBundle}:/etc/ssl/certs/ca-certificates.crt:ro"
    ];
    user = "${toString config.users.users.${const.username}.uid}:${toString config.users.groups.storage.gid}";
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.papra = {
      rule = "Host(`papra.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "papra";
      tls = { };
    };
    services.papra.loadBalancer.servers = lib.singleton {
      url = "http://127.0.0.1:${toString (mylib.getUriPort (builtins.head config.virtualisation.oci-containers.containers.papra.ports))}";
    };
  };
}

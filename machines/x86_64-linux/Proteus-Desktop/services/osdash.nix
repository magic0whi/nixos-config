{
  config,
  const,
  lib,
  mylib,
  ...
}:
let
  osdash_port = 5601;
  hostname = config.networking.hostName;
in
{
  vars.hostAddrs.${hostname}.easytier.subdomains =
    let
      subs = [ "osdash" ];
    in
    {
      A = subs;
      AAAA = subs;
    };
  sops =
    let
      restartUnits = [ "${config.virtualisation.oci-containers.containers.osdash.serviceName}.service" ];
      sopsFile = const.secretsDir + "/${hostname}/osdash.sops.yaml";
    in
    {
      secrets = {
        osdash_client_secret = { inherit sopsFile restartUnits; };
        # osdash_password = { inherit sopsFile restartUnits; };
      };
      templates."osdash.yml" = {
        inherit restartUnits;
        owner = const.username; # sops-nix don't support specify uid while the image hardcoded 1000
        # https://github.com/opensearch-project/OpenSearch-Dashboards/blob/3.6.0/config/opensearch_dashboards.yml
        content = mylib.toYAML {
          server = {
            name = hostname;
            host = "0.0.0.0";
            port = 5601;
            customResponseHeaders.Access-Control-Allow-Credentials = true;
            # Disabling HTTPS on OpenSearch Dashboards
            ssl.enabled = false;
          };

          opensearch = {
            # ssl.certificateAuthorities = [ "/etc/ssl/certs/ca-certificates.crt" ]; # Sets for OpenSearch client only
            hosts = [ "https://nixos-search.${const.domain}/backend" ];
            username = "kibanaserver";
            # NOTE opensearch-dashboards don't suppport urlencode
            # password = config.sops.placeholder.osdash_password;
            requestHeadersAllowlist = [
              "securitytenant"
              "Authorization"
            ];
          };

          # Multitenancy
          opensearch_security = {
            multitenancy = {
              enabled = true;
              tenants.preferred = [
                "Private"
                "Global"
              ];
            };
            readonly_mode.roles = [ "kibana_read_only" ];
            auth.type = "openid";
            openid = {
              connect_url = "https://auth.${const.domain}/.well-known/openid-configuration";
              base_redirect_url = "https://osdash.${const.domain}";
              client_id = "osdash";
              client_secret = config.sops.placeholder.osdash_client_secret;
              scope = "openid profile email groups";
              # root_ca = "/etc/ssl/certs/ca-certificates.crt";
            };
          };
        };
      };
    };
  virtualisation.oci-containers = {
    backend = "docker";
    containers.osdash = {
      image = "opensearchproject/opensearch-dashboards:3.6.0";
      ports = [ "127.0.0.1:${toString osdash_port}:5601" ];
      # Cannot use NODE_USE_SYSTEM_CA=1, Node 20.18.3 < 22.15 / 23.9
      environment.NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
      volumes = [
        "${config.security.pki.caBundle}:/etc/ssl/certs/ca-certificates.crt:ro"
        "${config.sops.templates."osdash.yml".path}:/usr/share/opensearch-dashboards/config/opensearch_dashboards.yml:ro"
      ];
    };
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.osdash = {
      rule = "Host(`osdash.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "osdash";
      tls = { };
    };
    services.osdash.loadBalancer.servers = lib.singleton { url = "http://127.0.0.1:${toString osdash_port}"; };
  };
}

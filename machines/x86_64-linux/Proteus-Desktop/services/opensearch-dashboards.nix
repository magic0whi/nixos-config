{
  config,
  const,
  lib,
  ...
}:
let
  opensearch_dashboards_port = 5601;
in
{
  sops =
    let
      restartUnits = [ "${config.virtualisation.oci-containers.containers.opensearch-dashboards.serviceName}.service" ];
    in
    {
      secrets.opensearch_dashboards_password = {
        sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
        inherit restartUnits;
      };
      templates."opensearch_dashboards.yml" = {
        inherit restartUnits;
        owner = const.username; # sops-nix don't support specify uid while the image hardcoded 1000
        # https://github.com/opensearch-project/OpenSearch-Dashboards/blob/3.6.0/config/opensearch_dashboards.yml
        content = ''
          server:
            name: opensearch_dashboards
            host: 0.0.0.0
            port: 5601
            customResponseHeaders : { "Access-Control-Allow-Credentials" : "true" }
            # Disabling HTTPS on OpenSearch Dashboards
            ssl.enabled: false

          # opensearch.ssl.verificationMode: none
          opensearch:
            # ssl.certificateAuthorities: [ "/etc/ssl/certs/ca-certificates.crt" ]
            hosts: [ "https://nixos-search.${const.domain}/backend" ]
            username: kibanaserver
            # NOTE opensearch-dashboards don't suppport urlencode
            password: '${config.sops.placeholder.opensearch_dashboards_password}'
            requestHeadersAllowlist: ["securitytenant","Authorization"]

          # Multitenancy
          opensearch_security:
            multitenancy.enabled: true
            multitenancy.tenants.preferred: ["Private", "Global"]
            readonly_mode.roles: ["kibana_read_only"]
            auth.type: openid
            openid:
              connect_url: https://auth.${const.domain}/.well-known/openid-configuration
              base_redirect_url: "https://opensearch-dashboards.proteus.eu.org"
              client_id: opensearch-dashboards
              client_secret: ${config.sops.placeholder.opensearch-dashboards_client_secret}
              scope: openid profile email groups
              # root_ca: /etc/ssl/certs/ca-certificates.crt
        '';
      };
    };
  virtualisation.oci-containers = {
    backend = "docker";
    containers.opensearch-dashboards = {
      image = "opensearchproject/opensearch-dashboards:3.6.0";
      ports = [ "127.0.0.1:${toString opensearch_dashboards_port}:5601" ];
      environment.NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
      volumes = [
        "${config.security.pki.caBundle}:/etc/ssl/certs/ca-certificates.crt:ro"
        "${
          config.sops.templates."opensearch_dashboards.yml".path
        }:/usr/share/opensearch-dashboards/config/opensearch_dashboards.yml:ro"
      ];
    };
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.opensearch-dashboards = {
      rule = "Host(`opensearch-dashboards.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "opensearch-dashboards";
      tls = { };
    };
    services.opensearch-dashboards.loadBalancer.servers = lib.singleton {
      url = "http://127.0.0.1:${toString opensearch_dashboards_port}";
    };
  };
}

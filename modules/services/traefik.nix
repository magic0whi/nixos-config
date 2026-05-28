{
  config,
  lib,
  myvars,
  ...
}:
let
  server_pub_crt = "${myvars.secretsDir}/proteus_server.pub.pem";
in
{
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [ 443 ]; # QUIC
  };
  sops.secrets."traefik_server.priv.pem" = {
    sopsFile = "${myvars.secretsDir}/proteus_server.priv.pem.sops";
    format = "binary";
    owner = config.systemd.services.traefik.serviceConfig.User;
    restartUnits = [ "traefik.service" ];
  };
  services.traefik = {
    enable = true;
    # Static configuration handles entrypoints (ports) and global settings
    staticConfigOptions = {
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };
      api.dashboard = true;
      entryPoints = {
        # Force HTTP to HTTPS redirect globally
        web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
        websecure = {
          address = ":443";
          http3 = { }; # QUIC
          # Prevent large video uploads from timing out and throwing Error 499. Ref:
          # https://web.archive.org/web/20260217103328/https://docs.immich.app/administration/reverse-proxy/#traefik-proxy-example-config
          transport.respondingTimeouts = {
            readTimeout = "600s";
            idleTimeout = "600s";
          };
        };
      };
    };
    # Dynamic configuration defines routing rules, backend services, and certificate management.
    dynamicConfigOptions = {
      # Establish the default fallback certificate.
      # This is critical for TCP clients (like `ldapsearch`) that do not send Server Name Indication (SNI) data during
      # the TLS handshake. Without this, Traefik serves an untrusted dummy certificate.
      tls.stores.default.defaultCertificate = {
        certFile = server_pub_crt;
        keyFile = config.sops.secrets."traefik_server.priv.pem".path;
      };
      # For other domains
      # tls.certificates = [{certFile = server_pub_crt; keyFile = config.sops.secrets."traefik_server.priv.pem".path;}];
      http = {
        middlewares.authelia-auth.forwardAuth = {
          # Tell Traefik where to ask whether a user is authenticated
          address = lib.mkDefault "https://auth.${myvars.domain}/api/authz/forward-auth?authelia_url=https://auth.${myvars.domain}/";
          trustForwardHeader = true;
          authResponseHeaders = [
            "Remote-User"
            "Remote-Groups"
            "Remote-Email"
            "Remote-Name"
          ];
        };
        routers = {
          traefik-dashboard = {
            # rule = "Host(`example.${myvars.domain}`)";
            entryPoints = [ "websecure" ];
            middlewares = [ "authelia-auth" ]; # `authelia-auth` Protect the dashboard
            service = "api@internal";
            tls = { }; # enables TLS using the default cert
          };
        };
      };
    };
  };
}

## TODO: Split to a shared traefik.nix onto NixOS::Headless::Traefik
{
  config,
  myvars,
  ...
}:
let
  server_pub_crt = "${myvars.secrets_dir}/proteus_server.pub.pem";
in
{
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [ 443 ];
  };
  sops.secrets."traefik_server.priv.pem" = {
    sopsFile = "${myvars.secrets_dir}/proteus_server.priv.pem.sops";
    format = "binary";
    owner = config.systemd.services.traefik.serviceConfig.User;
    restartUnits = [ "traefik.service" ];
  };
  services.traefik = {
    enable = true;
    staticConfigOptions = {
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };
      api.dashboard = true;
      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
        websecure = {
          address = ":443";
          http3 = { };
          transport.respondingTimeouts = {
            readTimeout = "600s";
            idleTimeout = "600s";
          };
        };
      };
    };
    dynamicConfigOptions = {
      tls.stores.default.defaultCertificate = {
        certFile = server_pub_crt;
        keyFile = config.sops.secrets."traefik_server.priv.pem".path;
      };
      http = {
        middlewares.authelia-auth.forwardAuth = {
          address = "https://auth.${myvars.domain}/api/authz/forward-auth?authelia_url=https://auth.${myvars.domain}/";
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
            rule = "Host(`traefik-desktop.${myvars.domain}`)";
            entryPoints = [ "websecure" ];
            middlewares = [ "authelia-auth" ];
            service = "api@internal";
            tls = { };
          };
          sb = {
            rule = "Host(`sb-desktop.${myvars.domain}`)";
            entryPoints = [ "websecure" ];
            middlewares = [ "authelia-auth" ];
            service = "sb-dashboard";
            tls = { };
          };
        };
        services.sb-dashboard.loadBalancer.servers = [ { url = "http://127.0.0.1:9091"; } ];
      };
    };
  };
}

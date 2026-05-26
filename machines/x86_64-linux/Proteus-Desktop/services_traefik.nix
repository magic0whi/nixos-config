## TODO: Extract to their respective modules
{
  config,
  lib,
  mylib,
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
          s3 = {
            rule = ''Host(`s3.${myvars.domain}`) || HostRegexp(`^[^.]+\.s3\.${lib.escapeRegex myvars.domain}$`)'';
            entryPoints = [ "websecure" ];
            service = "s3";
            tls = { };
          };
          s3-pub = {
            rule = builtins.concatStringsSep " " [
              "Host(`s3-pub.${myvars.domain}`)"
              ''|| HostRegexp(`^[^.]+\.s3-pub\.${lib.escapeRegex myvars.domain}$`)''
            ];
            entryPoints = [ "websecure" ];
            service = "s3-pub";
            tls = { };
          };
          garage-webui = {
            rule = "Host(`garage.${myvars.domain}`)";
            entryPoints = [ "websecure" ];
            middlewares = [ "authelia-auth" ];
            service = "garage-webui";
            tls = { };
          };
        };
        services = {
          sb-dashboard.loadBalancer.servers = [ { url = "http://127.0.0.1:9091"; } ];
          s3.loadBalancer =
            let
              cfg = config.services.garage.settings;
            in
            {
              servers = [ { url = "http://${cfg.s3_api.api_bind_addr}"; } ]; # Default :3900
              # Probe the admin port
              healthCheck = {
                port = toString (mylib.get_uri_port cfg.admin.api_bind_addr);
                path = "/health";
              };
            };
          s3-pub.loadBalancer =
            let
              cfg = config.services.garage.settings;
            in
            {
              servers = [ { url = "http://${cfg.s3_web.bind_addr}"; } ]; # Default :3902
              # Probe the admin port
              healthCheck = {
                port = toString (mylib.get_uri_port cfg.admin.api_bind_addr);
                path = "/health";
              };
            };
          garage-webui.loadBalancer.servers = [
            {
              url =
                let
                  find_first_prefix = key: list: builtins.elemAt list (lib.lists.findFirstIndex (i: lib.hasPrefix key i) null list);
                  port = lib.last (
                    lib.splitString "=" (find_first_prefix "PORT=" config.systemd.services.garage-webui.serviceConfig.Environment)
                  );
                in
                "http://127.0.0.1:${port}"; # Default :3909
            }
          ];
        };
      };
    };
  };
}

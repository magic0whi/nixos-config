{
  config,
  myvars,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [ opensearch-cli ];
  networking.firewall.allowedTCPPorts = [ 9200 ];
  services.opensearch = {
    enable = true;
    settings = {
      "network.host" = "127.0.0.1";
      "http.cors.enabled" = "true";
      "http.cors.allow-origin" = "https://nixos-search.${myvars.domain}";
      "http.cors.allow-credentials" = "true";
      "http.cors.allow-headers" = "X-Requested-With,X-Auth-Token,Content-Type,Content-Length,Authorization";
    };
  };
  services.caddy.virtualHosts."http://nixos-search.${myvars.domain}:${toString myvars.networking.caddyPort}" =
    let
      web_root = "${myvars.storagePath}/www";
    in
    {
      listenAddresses = [
        "127.0.0.1"
        "[::1]"
      ];
      extraConfig = ''
        root * ${web_root}/nixos-search
        file_server
        # https://caddyserver.com/docs/caddyfile/patterns#single-page-apps-spas
        try_files {path} /index.html
        encode
      '';
    };

  services.traefik.dynamicConfigOptions.http = {
    middlewares.strip-backend-prefix.stripPrefix.prefixes = [ "/backend" ];
    routers.nixos-search_backend = {
      rule = "Host(`nixos-search.${myvars.domain}`) && PathPrefix(`/backend`)";
      entryPoints = [ "websecure" ];
      middlewares = [ "strip-backend-prefix" ];
      service = "nixos-search_backend";
      tls = { };
    };
    services.nixos-search_backend.loadBalancer.servers = [
      { url = "http://127.0.0.1:${toString config.services.opensearch.settings."http.port"}"; }
    ];
  };
}

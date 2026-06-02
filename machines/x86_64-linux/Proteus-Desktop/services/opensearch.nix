{ myvars, pkgs, ... }:
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
}

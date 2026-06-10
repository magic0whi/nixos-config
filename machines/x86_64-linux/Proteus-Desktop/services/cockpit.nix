{
  config,
  myvars,
  pkgs,
  ...
}:
{
  services.cockpit = {
    enable = true;
    allowed-origins = [ "https://cockpit-desktop.${myvars.domain}" ];
    settings = {
      WebService = {
        ProtocolHeader = "X-Forwarded-Proto";
        ForwardedForHeader = "X-Forwarded-For";
      };
      # Tried, no luck
      # OAuth.URL = "https://auth.${myvars.domain}/api/oidc/authorization?client_id=cockpit&nonce=CockpitNonce123&state=CockpitState1234&response_mode=fragment&response_type=id_token&scope=openid+email+profile+groups&redirect_uri=https://cockpit-desktop.${myvars.domain}/callback";
    };
    plugins = with pkgs; [
      cockpit-machines
      # cockpit-zfs
    ];
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.immich = {
      rule = "Host(`cockpit-desktop.${myvars.domain}`)";
      entryPoints = [ "websecure" ];
      service = "cockpit";
      tls = { };
    };
    services.cockpit.loadBalancer.servers = [ { url = "http://127.0.0.1:${toString config.services.cockpit.port}"; } ];
  };
}

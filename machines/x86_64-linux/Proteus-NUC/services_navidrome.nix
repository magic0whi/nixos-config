{
  config,
  myvars,
  ...
}: {
  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "${config.users.users.${myvars.username}.home}/Music";
      ExtAuth = {
        TrustedSources = "127.0.0.1/32,::1/128";
        LogoutURL = "https://auth.${myvars.domain}/logout";
      };
    };
  };
  services.traefik.dynamicConfigOptions.http = {
    routers = {
      navidrome = {
        rule = "Host(`navidrome.${myvars.domain}`)";
        entryPoints = ["websecure"];
        middlewares = ["authelia-auth"];
        service = "navidrome";
        tls = {};
      };
      # Authentication bypass for share and subsonic endpoints
      navidrome-public = {
        rule = "Host(`navidrome.${myvars.domain}`) && (PathPrefix(`/share/`) || PathPrefix(`/rest/`))";
        entryPoints = ["websecure"];
        service = "navidrome";
        tls = {};
      };
    };
    services.navidrome.loadBalancer.servers = [
      (with config.services.navidrome.settings; {url = "http://${Address}:${toString Port}";})
    ];
  };
}

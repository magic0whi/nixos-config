{
  config,
  lib,
  myvars,
  ...
}: {
  services.navidrome = {
    enable = true;
    settings = {
      BaseUrl = "https://navidrome.${myvars.domain}";
      MusicFolder = config.home-manager.users.${myvars.username}.xdg.userDirs.music;
      ExtAuth = {
        TrustedSources = "127.0.0.1/32,::1/128";
        LogoutURL = "https://auth.${myvars.domain}/logout?rd=https://navidrome.${myvars.domain}";
      };
    };
  };
  systemd.services.navidrome.serviceConfig = {
    ProtectHome = lib.mkForce "tmpfs";
    BindReadOnlyPaths = [config.home-manager.users.${myvars.username}.xdg.userDirs.music];
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

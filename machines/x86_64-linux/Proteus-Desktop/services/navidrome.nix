{
  config,
  # lib,
  const,
  ...
}:
{
  systemd.services.navidrome.unitConfig.RequiresMountsFor = [ const.storagePath ];
  services.navidrome = {
    enable = true;
    settings = {
      BaseUrl = "https://navidrome.${const.domain}";
      # MusicFolder = config.home-manager.users.${const.username}.xdg.userDirs.music;
      MusicFolder = "${const.storagePath}/share/Music";
      # ExtAuth = {
      #   TrustedSources = "127.0.0.1/32,::1/128";
      #   LogoutURL = "https://auth.${const.domain}/logout?rd=https://navidrome.${const.domain}";
      # };
    };
  };
  # If use ~/Music
  # systemd.services.navidrome.serviceConfig = {
  #   ProtectHome = lib.mkForce "tmpfs";
  #   BindReadOnlyPaths = [ config.home-manager.users.${const.username}.xdg.userDirs.music ];
  # };
  services.traefik.dynamicConfigOptions.http = {
    routers = {
      navidrome = {
        rule = "Host(`navidrome.${const.domain}`)";
        entryPoints = [ "websecure" ];
        # middlewares = [ "authelia-auth" ]; # OIDC doesn't play well for clients
        service = "navidrome";
        tls = { };
      };
      # Authentication bypass for share and subsonic endpoints
      navidrome-public = {
        rule = "Host(`navidrome.${const.domain}`) && (PathPrefix(`/share/`) || PathPrefix(`/rest/`))";
        entryPoints = [ "websecure" ];
        service = "navidrome";
        tls = { };
      };
    };
    services.navidrome.loadBalancer.servers = [
      (with config.services.navidrome.settings; {
        url = "http://${Address}:${toString Port}";
      })
    ];
  };
}

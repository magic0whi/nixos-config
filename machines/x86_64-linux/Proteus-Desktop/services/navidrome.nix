{
  config,
  # lib,
  myvars,
  ...
}:
{
  systemd.services.navidrome.unitConfig.RequiresMountsFor = [ myvars.storagePath ];
  services.navidrome = {
    enable = true;
    settings = {
      BaseUrl = "https://navidrome.${myvars.domain}";
      # MusicFolder = config.home-manager.users.${myvars.username}.xdg.userDirs.music;
      MusicFolder = "${myvars.storagePath}/share/Music";
      # ExtAuth = {
      #   TrustedSources = "127.0.0.1/32,::1/128";
      #   LogoutURL = "https://auth.${myvars.domain}/logout?rd=https://navidrome.${myvars.domain}";
      # };
    };
  };
  # If use ~/Music
  # systemd.services.navidrome.serviceConfig = {
  #   ProtectHome = lib.mkForce "tmpfs";
  #   BindReadOnlyPaths = [ config.home-manager.users.${myvars.username}.xdg.userDirs.music ];
  # };
  services.traefik.dynamicConfigOptions.http = {
    routers = {
      navidrome = {
        rule = "Host(`navidrome.${myvars.domain}`)";
        entryPoints = [ "websecure" ];
        # middlewares = [ "authelia-auth" ]; # OIDC doesn't play well for clients
        service = "navidrome";
        tls = { };
      };
      # Authentication bypass for share and subsonic endpoints
      navidrome-public = {
        rule = "Host(`navidrome.${myvars.domain}`) && (PathPrefix(`/share/`) || PathPrefix(`/rest/`))";
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

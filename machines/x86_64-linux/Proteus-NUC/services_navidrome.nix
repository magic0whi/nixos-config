{
  config,
  myvars,
  ...
}: {
  services.navidrome = {
    enable = true;
    settings.MusicFolder = "${config.users.users.${myvars.username}.home}/Music";
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.navidrome = {
      rule = "Host(`navidrome.${myvars.domain}`)";
      entryPoints = ["websecure"];
      service = "navidrome";
      tls = {};
    };
    services.navidrome.loadBalancer.servers = [
      (with config.services.navidrome.settings; {url = "http://${Address}:${toString Port}";})
    ];
  };
}

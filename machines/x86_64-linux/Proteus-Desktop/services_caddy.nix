{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
let
  # web_root = "/srv/www";
  web_root = "${myvars.storagePath}/www";
  caddy_port = 8080;
in
{
  # systemd.tmpfiles.settings."10-caddy-create-web-root".${web_root}.d = {
  #   user = config.services.caddy.user;
  #   group = config.services.caddy.user;
  #   mode = "0755";
  # };

  services.caddy = {
    enable = true;
    # Caddy doesn't need to bind to public ports (80/443) since Traefik handles that. We can tell Caddy's global config
    # not to attempt ACME/HTTPS bindings.
    globalConfig = "auto_https off";
    virtualHosts = {
      "http://notebook.${myvars.domain}:${toString caddy_port}" = {
        listenAddresses = [
          "127.0.0.1"
          "[::1]"
        ];
        extraConfig = ''
          # respond "Hello, world!" # For debug
          root * ${web_root}/notebook
          file_server
        '';
      };
      "http://nixos-search.${myvars.domain}:${toString caddy_port}" = {
        listenAddresses = [
          "127.0.0.1"
          "[::1]"
        ];
        extraConfig = ''
          root * ${web_root}/nixos-search
          file_server
        '';
      };
    };
  };
  # For CI deploy
  users.users.${config.services.caddy.user} = {
    shell = config.users.defaultUserShell; # rrsync cannot use alone with nologin
    openssh.authorizedKeys.keys = [
      ''command="${lib.getExe pkgs.rrsync} ${web_root}",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty,no-user-rc ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIqIOCSIyS87hlO8H4QnCuuN5NAZxe6Pz9CF6BCqsf4 caddy@Proteus-NUC''
    ];
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.notebook = {
      rule = "Host(`notebook.${myvars.domain}`)";
      entryPoints = [ "websecure" ];
      service = "caddy";
      tls = { };
    };
    routers.nixos-search = {
      rule = "Host(`nixos-search.${myvars.domain}`)";
      entryPoints = [ "websecure" ];
      service = "caddy";
      tls = { };
    };
    services.caddy.loadBalancer.servers = [ { url = "http://127.0.0.1:${toString caddy_port}"; } ];
  };
}

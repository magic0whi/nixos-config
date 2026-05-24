{
  config,
  lib,
  mylib,
  myvars,
  pkgs,
  ...
}: let
  web_root = "/srv/www";
in {
  services.caddy = {
    enable = true;
    # Caddy doesn't need to bind to public ports (80/443) since Traefik handles that. We can tell Caddy's global config
    # not to attempt ACME/HTTPS bindings.
    globalConfig = ''auto_https off'';
    virtualHosts."http://notebook.${myvars.domain}:8080" = {
      listenAddresses = ["127.0.0.1" "[::1]"];
      extraConfig = ''
        # respond "Hello, world!" # For debug
        root * ${web_root}
        file_server
      '';
    };
  };
  # For CI deploy
  users.users.caddy = {
    shell = config.users.defaultUserShell; # rrsync cannot use alone with nologin
    openssh.authorizedKeys.keys = [
      ''command="${lib.getExe pkgs.rrsync} ${web_root}",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty,no-user-rc ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIqIOCSIyS87hlO8H4QnCuuN5NAZxe6Pz9CF6BCqsf4 caddy@Proteus-NUC''
    ];
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.notebook = {
      rule = "Host(`notebook.${myvars.domain}`)";
      entryPoints = ["websecure"];
      service = "notebook";
      tls = {};
    };
    services.notebook.loadBalancer.servers = [
      {
        url = let
          find_first_infix = key: set:
            builtins.elemAt
            (lib.attrNames set) (lib.lists.findFirstIndex (i: lib.hasInfix key i) null (lib.attrNames set));
          port =
            toString (mylib.get_uri_port
              (find_first_infix "notebook.${myvars.domain}" config.services.caddy.virtualHosts));
        in "http://127.0.0.1:${port}";
      }
    ];
  };
}

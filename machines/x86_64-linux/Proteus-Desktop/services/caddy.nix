{
  config,
  lib,
  mylib,
  const,
  pkgs,
  ...
}:
let
  web_root = "${const.storagePath}/www";
in
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains =
        let
          subs = [
            "noogle"
            "notebook"
            "algo-archive"
          ];
        in
        {
          A = subs;
          AAAA = subs;
        };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  systemd.services.caddy.unitConfig.RequiresMountsFor = [ const.storagePath ];
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
      "http://notebook.${const.domain}:${toString const.networking.caddyPort}" = mylib.mkCaddyVHost "${web_root}/notebook";
      "http://noogle.${const.domain}:${toString const.networking.caddyPort}" = mylib.mkCaddyVHost "${web_root}/noogle";
      "http://algo-archive.${const.domain}:${toString const.networking.caddyPort}" = {
        listenAddresses = [
          "127.0.0.1"
          "[::1]"
        ];
        extraConfig = ''
          # respond "Hello, world!" # For debug
          root * ${web_root}/algorithm-archive

          # file_server directive is required if serve static files from disk
          file_server browse

          # Enable compress, default zstd
          encode
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
    routers.caddy = {
      rule = lib.concatStringsSep " || " (
        map (i: "Host(`${lib.removeSuffix ":${toString const.networking.caddyPort}" (lib.removePrefix "http://" i)}`)") (
          builtins.attrNames config.services.caddy.virtualHosts
        )
      );
      entryPoints = [ "websecure" ];
      service = "caddy";
      tls = { };
      priority = 10;
    };
    services.caddy.loadBalancer.servers = [ { url = "http://127.0.0.1:${toString const.networking.caddyPort}"; } ];
  };
}

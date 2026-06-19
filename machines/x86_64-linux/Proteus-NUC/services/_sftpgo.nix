{
  config,
  const,
  ...
}:
{
  services.sftpgo = {
    enable = true;
    user = const.username;
    group = const.username;
    extraReadWriteDirs = [
      /srv/aria2
      config.home-manager.users.${const.username}.xdg.userDirs.documents
    ];
    settings = {
      httpd = {
        bindings = [
          # Allow reverse proxy
          {
            port = 8081;
            client_ip_proxy_header = "X-Forwarded-For";
            proxy_allowed = [ "127.0.0.1" ];
          }
          {
            address = "[::1]";
            port = 8081;
            client_ip_proxy_header = "X-Forwarded-For";
            proxy_allowed = [ "::1" ];
          }
        ];
      };
      webdavd.bindings = [
        {
          port = 8443;
          client_ip_proxy_header = "X-Forwarded-For";
          proxy_allowed = [ "127.0.0.1" ];
        }
        {
          address = "[::1]";
          port = 8443;
          client_ip_proxy_header = "X-Forwarded-For";
          proxy_allowed = [ "::1" ];
        }
      ];
    };
  };
  services.traefik.dynamicConfigOptions.http = {
    routers = {
      sftpgo-webui = {
        rule = "Host(`sftpgo.${const.domain}`)";
        entryPoints = [ "websecure" ];
        service = "sftpgo-webui";
        tls = { };
      };
      sftpgo-webdav = {
        rule = "Host(`webdav.${const.domain}`)";
        entryPoints = [ "websecure" ];
        service = "sftpgo-webdav";
        tls = { };
      };
    };
    services =
      let
        cfg = config.services.sftpgo.settings;
        httpd_port = toString (builtins.head cfg.httpd.bindings).port;
        webdavd_port = toString (builtins.head cfg.webdavd.bindings).port;
      in
      {
        sftpgo-webui.loadBalancer.servers = [
          { url = "http://127.0.0.1:${httpd_port}"; }
          { url = "http://[::1]:${httpd_port}"; }
        ];
        sftpgo-webdav.loadBalancer.servers = [
          { url = "http://127.0.0.1:${webdavd_port}"; }
          { url = "http://[::1]:${webdavd_port}"; }
        ];
      };
  };
}

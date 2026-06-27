{
  config,
  const,
  mylib,
  ...
}:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "atuin" ];
        AAAA = [ "atuin" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  sops =
    let
      restartUnits = [ "atuin.service" ];
    in
    {
      secrets.atuin_db_password = {
        inherit restartUnits;
        sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
      };
      templates."atuin.env" = {
        inherit restartUnits;
        # If using unix socket, Atuin doesn't allow empty host, add a bogus host "114514"
        content = mylib.toEnv {
          ATUIN_DB_URI = "postgres://atuin:${config.sops.placeholder.atuin_db_password}@114514/?host=/run/postgresql";
        };
        # content = mylib.toEnv {
        #   ATUIN_DB_URI = "postgres://atuin:${config.sops.placeholder.atuin_db_password}@postgresql.${const.domain}/atuin?sslmode=require";
        # };
      };
    };
  services.atuin = {
    enable = true;
    port = 8889; # default 8888
    environmentFile = config.sops.templates."atuin.env".path;
    openRegistration = true;
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.atuin = {
      rule = "Host(`atuin.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "atuin";
      tls = { };
    };
    services.atuin.loadBalancer = {
      servers = [ { url = "http://127.0.0.1:${toString config.services.atuin.port}"; } ];
      healthCheck.path = "/healthz";
    };
  };
}

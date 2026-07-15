# TIP: # For `ql` command , run `docker exec -it qinglong /ql/shell/update.sh`

{
  mylib,
  lib,
  const,
  config,
  ...
}:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "ql" ];
        AAAA = [ "ql" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  virtualisation.oci-containers.containers.qinglong = {
    image = "ghcr.io/whyour/qinglong@sha256:752926c705759f51032593b546adef5e7ab7e365784df7bf996a3b4ac68ce4fd";
    # autoStart = false; # equivalent to 'restart: unless-stopped', default true
    ports = [ "127.0.0.1:5700:5700" ];

    environment.TZ = "Asia/Hong_Kong";

    volumes = [ "${const.storagePath}/qinglong:/ql/data" ];
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.qinglong = {
      rule = "Host(`ql.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "qinglong";
      tls = { };
    };
    services.qinglong.loadBalancer.servers = lib.singleton {
      url = "http://127.0.0.1:${toString (mylib.getUriPort (builtins.head config.virtualisation.oci-containers.containers.qinglong.ports))}";
    };
  };
}

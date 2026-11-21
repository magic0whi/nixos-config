{
  const,
  config,
  ...
}:
let
  hostname = config.networking.hostName;
  sub = "${hostname}.sb";
in
{
  vars = {
    hostAddrs.${hostname}.easytier.subdomains = {
      A = [ sub ];
      AAAA = [ sub ];
    };
  };

  # Two backends: h2c for native gRPC, HTTP/1.1 for the dashboard's gRPC-Web POSTs and grpc-websockets streams.
  services.traefik.dynamicConfigOptions.http = {
    routers = {
      sb = {
        rule = "Host(`${sub}.${const.domain}`)";
        entryPoints = [ "websecure" ];
        priority = 10;
        service = "sb";
        tls = { };
      };
      sb-grpc = {
        rule = "Host(`${sub}.${const.domain}`) && HeaderRegexp(`Content-Type`, `^application/grpc([;+]|$)`)";
        entryPoints = [ "websecure" ];
        priority = 100; # Both routers match the Host, the more specific one must win
        service = "sb-grpc";
        tls = { };
      };
    };
    services =
      let
        addr = with const.sb.api; "${listen}:${toString port}";
      in
      {
        sb.loadBalancer.servers = [ { url = "http://${addr}"; } ];
        sb-grpc.loadBalancer.servers = [ { url = "h2c://${addr}"; } ];
      };
  };
}

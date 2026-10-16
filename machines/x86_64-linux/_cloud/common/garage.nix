# TIP: To add other nodes: `garage -h $ID@127.0.0.1:3901 node connect "<node-id>@<node-domain>:3901"`
{
  config,
  const,
  mylib,
  lib,
  ...
}:
let
  rpc_port = 3901;
  hostname = config.networking.hostName;
in
{
  networking.firewall.allowedTCPPorts = [ rpc_port ];

  sops =
    let
      sopsFile = "${const.secretsDir}/gcp.sops.yaml";
      restartUnits = [ "garage-webui.service" ];
    in
    {
      secrets = {
        garage_rpc_secret = { inherit sopsFile restartUnits; };
        garage_admin_token = { inherit sopsFile restartUnits; };
      };
      templates."garage-webui.env" = {
        inherit restartUnits;
        content = mylib.toEnv {
          # garage-webui use http://<rpc_public_addr>:3900 by default
          S3_ENDPOINT_URL = "https://${lib.toLower hostname}.s3.${const.domain}${config.services.traefik.staticConfigOptions.entryPoints.websecure.address}";
        };
      };
    };

  services.garage.settings = {
    rpc_bind_addr = "[::]:${toString rpc_port}";
    rpc_public_addr = "${hostname}.proteus11451.online:${toString rpc_port}";
    s3_api.s3_region = "us-east-1"; # the default name, should keep same across the cluster
    replication_factor = 2; # allows one node die
  };
}

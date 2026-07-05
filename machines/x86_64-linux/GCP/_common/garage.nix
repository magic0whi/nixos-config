# TIP: To add other nodes: `garage -h $ID@127.0.0.1:3901 node connect "<node-id>@<node-domain>:3901"`
{
  config,
  const,
  ...
}:
let
  rpc_port = 3901;
in
{
  networking.firewall.allowedTCPPorts = [ rpc_port ];

  sops.secrets =
    let
      sopsFile = "${const.secretsDir}/gcp.sops.yaml";
    in
    {
      garage_rpc_secret = { inherit sopsFile; };
      garage_admin_token = { inherit sopsFile; };
    };

  services.garage.settings = {
    rpc_bind_addr = "[::]:${toString rpc_port}";
    rpc_public_addr = "${config.networking.hostName}.proteus11451.online:${toString rpc_port}";
    s3_api.s3_region = "us-east-1"; # the default name, should keep same across the cluster
    replication_factor = 2; # allows one node die
  };
}

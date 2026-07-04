{ const, ... }:
{
  sops.secrets =
    let
      sopsFile = "${const.secretsDir}/gcp.sops.yaml";
    in
    {
      garage_rpc_secret = { inherit sopsFile; };
      garage_admin_token = { inherit sopsFile; };
    };

  services.garage.settings.s3_api.s3_region = "us-east-1";
}

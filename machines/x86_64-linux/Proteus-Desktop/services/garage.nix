{
  config,
  const,
  ...
}:
{
  sops =
    let
      sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
    in
    {
      secrets = {
        garage_rpc_secret = { inherit sopsFile; };
        garage_admin_token = { inherit sopsFile; };
      };
    };

  # systemd.tmpfiles.settings."10-garage-create-dir" = {
  #   ${config.services.garage.settings.data_dir}.d = {
  #     group = "storage";
  #     mode = "2775";
  #   };
  #   ${config.services.garage.settings.metadata_dir}.d = {
  #     group = "storage";
  #     mode = "2775";
  #   };
  # };

  systemd.services.garage = {
    unitConfig.RequiresMountsFor = [ const.storagePath ];
    serviceConfig = {
      SupplementaryGroups = [ "storage" ];
      # `DynamicUser=true` implies `ProtectSystem=strict`
      # `metadata_dir` is added defaultly, ref:
      # https://github.com/NixOS/nixpkgs/blob/15f4ee454b1dce334612fa6843b3e05cf546efab/nixos/modules/services/web-servers/garage.nix#L127-L149
      ReadWritePaths = [ "${const.storagePath}/garage/snapshots" ];
    };
  };
  services.garage.settings = {
    # metadata_dir = "${const.storagePath}/garage/meta"; # Garage recommends placing metadata on SSD
    metadata_snapshots_dir = "${const.storagePath}/garage/snapshots";
    data_dir = "${const.storagePath}/garage/data";
    s3_api.s3_region = "cn-east1-a";
  };
}

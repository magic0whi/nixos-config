# TIP: To add other nodes: `garage -h $ID@127.0.0.1:3901 node connect "<node-id>@<node-domain>:3901"`
{
  mySecrets,
  config,
  const,
  ...
}:
let
  rpc_port = 3901;
  hostname = config.networking.hostName;

  # The btrfs filesystem sits directly on the partition (OCI) or inside a LUKS
  # container (GCP)
  mount_point =
    (with config.disko.devices.disk.main.content.partitions.root; content.subvolumes or content.content.subvolumes)
    ."@garage".mountpoint;
in
{
  networking.firewall.allowedTCPPorts = [ rpc_port ];

  sops.secrets =
    let
      sopsFile = mySecrets + "/Cloud/garage.sops.yaml";
    in
    {
      garage-ui_client_secret = { inherit sopsFile; };
      garage_admin_token = { inherit sopsFile; };
      garage_rpc_secret = { inherit sopsFile; };
    };

  # Non-default paths mean the NixOS module wires them through ReadWritePaths instead of
  # StateDirectory, so the dirs must exist with the right ownership before garage starts
  systemd.tmpfiles.settings."10-garage-create-dir" = {
    ${config.services.garage.settings.metadata_dir}.d = {
      group = "storage";
      mode = "2775"; # setgid, so Garage-created subdirs inherit the group
    };
    ${config.services.garage.settings.data_dir}.d = {
      group = "storage";
      mode = "2775";
    };
  };

  systemd.services.garage = {
    unitConfig = {
      RequiresMountsFor = [ mount_point ];
      ConditionPathIsMountPoint = [ mount_point ];
    };
    serviceConfig.SupplementaryGroups = [ "storage" ];
  };

  services.garage.settings = {
    rpc_bind_addr = "[::]:${toString rpc_port}";
    rpc_public_addr = "${hostname}.${const.cloudDomain}:${toString rpc_port}";
    s3_api.s3_region = "us-east-1"; # the default name, should keep same across the cluster
    replication_factor = 2; # allows one node die
    metadata_dir = mount_point + "/meta";
    data_dir = mount_point + "/data";
  };

  virtualisation.oci-containers.containers.garage-ui.environment = {
    GARAGE_UI_AUTH_OIDC_CLIENT_ID = "garage-ui_gcp";
    # sing-box occupies 443, Traefik websecure listens on 8443. OIDC redirect URI is derived from root URL
    GARAGE_UI_SERVER_ROOT_URL = "https://${hostname}.garage.${const.domain}${config.services.traefik.staticConfigOptions.entryPoints.websecure.address}";
  };
}

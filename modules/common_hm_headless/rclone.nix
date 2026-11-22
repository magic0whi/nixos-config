{
  config,
  const,
  mySecrets,
  xdgRel,
  ...
}:
{
  sops.secrets.rclone_nextcloud_password.sopsFile = mySecrets + "/services/rclone.sops.yaml";

  programs.rclone = {
    enable = true;
    # Sensitive options (pass, access keys) point at sops secret files which
    # HM's rclone-config user service injects at login. `rclone config update`
    # obscures `pass` by itself, so `rclone_nextcloud_password` stores the
    # real password in plain text.
    remotes = {
      nextcloud = {
        config = {
          type = "webdav";
          url = "https://nextcloud.${const.domain}/remote.php/dav/files/proteus";
          vendor = "nextcloud";
          user = const.username;
        };
        secrets.pass = config.sops.secrets.rclone_nextcloud_password.path;
        # Mount the whole Nextcloud at ~/Nextcloud on login
        mounts."" = {
          enable = true;
          mountPoint = config.home.homeDirectory + "/Nextcloud";
        };
      };
      # garage-desktop = {
      #   config = {
      #     type = "s3";
      #     provider = "Other";
      #     region = "cn-east1-a";
      #     endpoint = "proteus-desktop.s3.${const.domain}";
      #   };
      #   secrets = {
      #     access_key_id = config.sops.secrets.rclone_garage_access_key_id.path;
      #     secret_access_key = config.sops.secrets.rclone_garage_secret_access_key.path;
      #   };
      # };
    };
  };
  home.persistence."/persistent".directories = [ "${xdgRel.configHome}/rclone" ];
}

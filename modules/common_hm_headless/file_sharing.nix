{lib, ...}: {
  programs.rclone.enable = true;

  services.syncthing.enable = lib.mkDefault true;
  systemd.user.services.syncthing.environment.STNODEFAULTFOLDER = "true";
  launchd.agents.syncthing.config.EnvironmentVariables.STNODEFAULTFOLDER = "true";
}

{
  lib,
  pkgs,
  ...
}:
{
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  systemd.services.console-blanking = {
    # Let monitor become blank after 2 mins, and 3 mins inactive to poweroff
    description = "Enable virtual console blanking and DPMS";
    after = [ "display-manager.service" ];
    environment.TERM = "linux";
    serviceConfig = {
      Type = "oneshot";
      StandardOutput = "tty";
      TTYPath = "/dev/console";
      ExecStart = "${lib.getExe' pkgs.util-linux "setterm"} --blank 2 --powerdown 3";
    };
    wantedBy = [ "multi-user.target" ];
  };
  # systemd.services.custom-sleep-actions = {
  #   description = "Customized sleep actions";
  #   before = [ "sleep.target" ];
  #   wantedBy = [ "sleep.target" ];
  #   unitConfig.StopWhenUnneeded = true; # Remove running status for oneshot
  #   serviceConfig =
  #     let
  #       systemctl = "${pkgs.systemd}/bin/systemctl";
  #     in
  #     {
  #       Type = "oneshot";
  #       RemainAfterExit = true; # Keeping running status during the sleep
  #       # `-` allows fail
  #       ExecStart = [ "-${systemctl} stop sing-box@config.service" ];
  #       ExecStop = [ "-${systemctl} start sing-box@config.service" ];
  #     };
  # };
}

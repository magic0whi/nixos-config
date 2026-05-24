{
  lib,
  pkgs,
  ...
}: {
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  systemd.services.console-blanking = {
    # Let monitor become blank after 2 mins, and 3 mins inactive to poweroff
    description = "Enable virtual console blanking and DPMS";
    after = ["display-manager.service"];
    environment.TERM = "linux";
    serviceConfig = {
      Type = "oneshot";
      StandardOutput = "tty";
      TTYPath = "/dev/console";
      ExecStart = "${lib.getExe' pkgs.util-linux "setterm"} --blank 2 --powerdown 3";
    };
    wantedBy = ["multi-user.target"];
  };
}

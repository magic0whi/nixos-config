{ lib, pkgs, ... }:
{
  # Niri v25.08 will create X11 sockets on disk, export $DISPLAY, and spawn `xwayland-satellite` on-demand when an X11
  # client connects
  home.packages = [ pkgs.pkgs.xwayland-satellite ];

  # NOTE: this executable is used by greetd to start a wayland session when system boot up with such a
  # vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config in NixOS
  # module
  home.file.".wayland-session" = {
    source = pkgs.writeScript "init-session" ''
      # trying to stop a previous niri session
      systemctl --user is-active niri.service && systemctl --user stop niri.service
      # and then we start a new one
      systemctl --user start --wait niri.service
    '';
    executable = true;
  };
  wayland.windowManager.niri = {
    enable = true;
    validation.enable = true;
  };
  xdg.configFile."systemd/user/niri.service.d/override.conf".text = ''
    [Service]
    ExecStopPost=-${lib.getExe' pkgs.systemd "systemctl"} --user stop graphical-session.target
  '';

}

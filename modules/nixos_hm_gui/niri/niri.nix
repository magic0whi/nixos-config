{ pkgs, ... }:
{
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
}

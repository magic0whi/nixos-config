{ pkgs, ... }:
{
  # Niri v25.08 will create X11 sockets on disk, export $DISPLAY, and spawn `xwayland-satellite` on-demand when an X11
  # client connects
  home.packages = [ pkgs.pkgs.xwayland-satellite ];

  # NOTE: this executable is used by greetd to start a wayland session when system boot up with such a
  # vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config in NixOS
  # module
  home.file.".wayland-session" = {
    source = "${pkgs.niri}/bin/niri-session";
    executable = true;
  };
  wayland.windowManager.niri = {
    enable = true;
    validation.enable = true;
  };
}

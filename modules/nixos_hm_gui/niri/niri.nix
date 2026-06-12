{
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # Niri v25.08 will create X11 sockets on disk, export $DISPLAY, and spawn `xwayland-satellite` on-demand when an X11 client connects
    xwayland-satellite
    # for Screenshot Annotation
    slurp
    grim
    satty
    niri
  ];

  xdg.configFile = {
    "niri/config.kdl".source = ./_niri/config.kdl;
    "niri/keybindings.kdl".source = ./_niri/keybindings.kdl;
    "niri/niri-hardware.kdl".source = ./_niri/niri-hardware.kdl;
    "niri/noctalia-shell.kdl".source = ./_niri/noctalia-shell.kdl;
    "niri/reorder-workspaces".source = ./_niri/reorder-workspaces.sh;
    "niri/spawn-at-startup".source = ./_niri/spawn-at-startup.kdl;
    "niri/window-rules".source = ./_niri/window-rules.kdl;
  };

  systemd.user.targets.niri-session.Unit = {
    Description = "niri compositor session";
    Documentation = [ "man:systemd.special(7)" ];
    BindsTo = [ "graphical-session.target" ];
    Wants = [
      "graphical-session-pre.target"
      "xdg-desktop-autostart.target"
    ];
    After = [ "graphical-session-pre.target" ];
    Before = [ "xdg-desktop-autostart.target" ];
  };

  # systemd.user.services.niri-flake-polkit = {
  #   Unit = {
  #     Description = "PolicyKit Authentication Agent provided by niri-flake";
  #     After = [ "graphical-session.target" ];
  #     Wants = [ "graphical-session-pre.target" ];
  #   };
  #   Install.WantedBy = [ "niri.service" ];
  #   Service = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
  #     Restart = "on-failure";
  #     RestartSec = 1;
  #     TimeoutStopSec = 10;
  #   };
  # };

  # NOTE: this executable is used by greetd to start a wayland session when system boot up with such a
  # vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config in NixOS
  # module
  home.file.".wayland-session" = {
    source = pkgs.writeScript "init-session" ''
      # trying to stop a previous niri session
      systemctl --user is-active niri.service && systemctl --user stop niri.service
      # and then we start a new one
      ${lib.getExe pkgs.niri}
    '';
    executable = true;
  };
}

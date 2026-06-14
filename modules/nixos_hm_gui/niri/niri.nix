{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.wayland.windowManager.niri = {
    enable = lib.mkEnableOption "Niri Window Manager custom configuration";
    systemd = {
      enable = lib.mkEnableOption null // {
        default = true;
        description = ''
          Whether to enable {file}`niri-session.target` on niri startup. This links to `graphical-session.target`.
          Some important environment variables will be imported to systemd and D-Bus user environment before reaching
          the target, including
          - `NIRI_SOCKET`
          - `DISPLAY`
          - `WAYLAND_DISPLAY`
          - `XDG_CURRENT_DESKTOP`
          - `XDG_SESSION_TYPE`
        '';
      };
      variables = lib.mkOption {
        type = with lib.types; listOf str;
        default = [
          "NIRI_SOCKET"
          "DISPLAY"
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP"
          "XDG_SESSION_TYPE"
        ];
        example = [ "--all" ];
        description = ''
          Environment variables to be imported in the systemd & D-Bus user environment.
        '';
      };
      extraCommands = lib.mkOption {
        type = with lib.types; listOf str;
        default = [
          "systemctl --user stop niri-session.target"
          "systemctl --user start niri-session.target"
        ];
        description = "Extra commands to be run after D-Bus activation.";
      };
    };
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      description = "Contents that will be written to config.kdl";
    };
    settings = lib.mkOption {
      type = lib.types.submodule (_: {
        options = {
          workspaces = lib.mkOption {
            type =
              with lib.types;
              addCheck (listOf str) (ws: builtins.length ws == 10) // { description = "list of strings with 10 elements"; };
            description = "Workspace names";
            default = [
              "1"
              "2"
              "3"
              "4"
              "5"
              "6"
              "7"
              "8"
              "9"
              "10"
            ];
          };
        };
      });
    };
  };
  config =
    let
      cfg = config.wayland.windowManager.niri;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        # Niri v25.08 will create X11 sockets on disk, export $DISPLAY, and spawn `xwayland-satellite` on-demand when an X11 client connects
        xwayland-satellite
        # For Screenshot Annotation
        slurp
        grim
        satty
        niri
      ];

      # Clean-up
      xdg.configFile."systemd/user/niri.service.d/override.conf".text = ''
        [Service]
        ExecStopPost=-${lib.getExe' pkgs.systemd "systemctl"} --user stop graphical-session.target
      '';

      systemd.user.targets.niri-session = lib.mkIf cfg.systemd.enable {
        Unit = {
          Description = "niri compositor session";
          Documentation = [ "man:systemd.special(7)" ];
          BindsTo = [ "graphical-session.target" ];
          Wants = [ "graphical-session-pre.target" ];
          After = [ "graphical-session-pre.target" ];
        };
      };
    };
}

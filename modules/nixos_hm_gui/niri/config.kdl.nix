{
  config,
  lib,
  pkgs,
  ...
}:
{
  config =
    let
      cfg = config.wayland.windowManager.niri;
    in
    lib.mkIf cfg.enable {
      wayland.windowManager.niri.extraConfig =
        let
          systemdActivation =
            let
              variables = builtins.concatStringsSep " " cfg.systemd.variables;
              extraCommands = builtins.concatStringsSep " " (map (f: "&& ${f}") cfg.systemd.extraCommands);
            in
            "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${variables} ${extraCommands}";
        in
        ''
          spawn-at-startup "${
            pkgs.writeShellScript "reorder-workspaces.sh" (
              lib.concatLines (
                builtins.genList (
                  i:
                  let
                    idx = toString (i + 1);
                    ws_name = builtins.elemAt cfg.settings.workspaces i;
                  in
                  ''niri msg action move-workspace-to-index ${idx} --reference "${ws_name}"''
                ) 10
              )
            )
          }"

          // Noctalia: use niri spawn-at-startup (systemd user service is deprecated upstream).
          // https://docs.noctalia.dev/getting-started/compositor-settings/niri/
          spawn-at-startup "noctalia-shell"
        ''
        + lib.optionalAttrs cfg.systemd.enable ''
          // systemd integration
          spawn-sh-at-startup "${systemdActivation}"
        '';

      xdg.configFile."niri/config.kdl".text = cfg.extraConfig;
    };
}

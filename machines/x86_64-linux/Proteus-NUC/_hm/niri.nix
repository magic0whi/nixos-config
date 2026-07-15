{
  lib,
  const,
  config,
  ...
}:
let
  ws_outputs = [
    "eDP-1"
    "DP-3"
    "DP-3"
    "DP-3"
    "DP-3"
    "DP-3"
    "DP-3"
    "DP-3"
    "DP-3"
    "DP-3"
  ];
in
{
  wayland.windowManager.niri.extraConfig = ''
    // =============================== hardware.kdl =======================================
    include "./hardware.kdl"
    // TIP: run `niri msg outputs` to find outputs
    output "DP-3" {
      scale 1.25
      mode "3440x1440@164.999"
      // Outputs are sized in logical pixels. for 2560x1440 with scale 1.25, the effective width is 2560/1.25=2048
      position x=2048 y=0
      // TODO fix edid, default edid causes flash
      // variable-refresh-rate
    }
    output "eDP-1" {
      scale 1.25
      mode "2560x1440@165.003"
      position x=0 y=0
      variable-refresh-rate
    }
  ''
  + lib.concatLines (
    lib.imap0 (i: ws: ''workspace "${ws}" { open-on-output "${builtins.elemAt ws_outputs i}"; }'') const.workspaces
  )
  + ''
    // ==================================================================================
  '';
  # Workaround: KDL don't allow duplicate node
  xdg.configFile."niri/hardware.kdl".text = ''debug { render-drm-device "/dev/dri/${
    if config.hardware.nvidia.sync then const.dgpu_sym_name else const.igpu_sym_name
  }"; }'';
}

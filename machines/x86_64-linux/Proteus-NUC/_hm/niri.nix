{ myvars, ... }:
{
  wayland.windowManager.niri.extraConfig = ''
    // =============================== hardware.kdl =======================================
    include "./hardware.kdl"
    // run `niri msg outputs` to find outputs
    output "DP-3" {
      scale 1.25
      mode "3440x1440@164.999"
      // Outputs are sized in logical pixels. for 2560x1440 with scale 1.25, the effective width is 2560/1.25=2048
      position x=2048 y=0
    }
    output "eDP-1" {
      scale 1.25
      mode "2560x1440@165.003"
      position x=0 y=0
    }

    workspace "1terminal" { open-on-output "DP-3"; }
    workspace "2browser" { open-on-output "DP-3"; }
    workspace "3chat" { open-on-output "DP-3"; }
    workspace "4gaming" { open-on-output "DP-3"; }
    workspace "5music" { open-on-output "DP-3"; }
    workspace "6file" { open-on-output "DP-3"; }
    workspace "7" { open-on-output "DP-3"; }
    workspace "8" { open-on-output "DP-3"; }
    workspace "9" { open-on-output "DP-3"; }

    workspace "0other" { open-on-output "eDP-1"; }
    // ==================================================================================
  '';
  # Workaround: KDL don't allow duplicate node
  xdg.configFile."niri/hardware.kdl".text = ''debug { render-drm-device "/dev/dri/${myvars.dgpu_sym_name}"; }'';
}

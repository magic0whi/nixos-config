{
  config,
  lib,
  myvars,
  ...
}: let
  monitor_cfg = {
    output = "eDP-1";
    mode = "highres";
    bitdepth = 10;
    cm = "adobe";
  };
  # Ref: https://wiki.hyprland.org/Configuring/Monitors/
  # TIP: ls /sys/class/drm/card*
  monitor_0 =
    monitor_cfg
    // {
      output = "eDP-1";
      scale = 1.25;
    }
    # 10-bit will cause the internal monitor flickering when using sync mode
    // lib.optionalAttrs config.wayland.windowManager.hyprland.nvidia_sync {bitdepth = 8;};
  monitor_1 =
    monitor_cfg
    // {
      output = "DP-3";
      position = "auto-up";
      scale = 1.67;
    };
in {
  wayland.windowManager.hyprland = {
    nvidia_sync = true;
    settings = {
      # May cause black screen if the bandwidth doesn't enough, disable it
      # config.render.cm_auto_hdr = 0;

      # TIP: Run `hyprctl monitors` to get the info.
      monitor = [monitor_0 monitor_1];
      workspace_rule = [
        {
          workspace = "1";
          monitor = monitor_1.output;
          default = true;
          layout = "scrolling";
        }
        {
          workspace = "2";
          monitor = monitor_1.output;
          layout = "scrolling";
        }
        {
          workspace = "3";
          monitor = monitor_1.output;
        }
        {
          workspace = "4";
          monitor = monitor_1.output;
        }
        {
          workspace = "5";
          monitor = monitor_1.output;
        }
        {
          workspace = "6";
          monitor = monitor_1.output;
        }
        {
          workspace = "7";
          monitor = monitor_1.output;
        }
        {
          workspace = "8";
          monitor = monitor_1.output;
        }
        {
          workspace = "9";
          monitor = monitor_1.output;
        }
        {
          workspace = "10";
          monitor = monitor_0.output;
        }
      ];
      # NOTE: Set "GDK_DPI_SCALE" globally is not recommend, makes firefox scale twice
      env =
        [{_args = ["STEAM_FORCE_DESKTOPUI_SCALING" "${toString monitor_1.scale}"];}]
        # Sync mode for Hyprland
        ++ lib.optional config.wayland.windowManager.hyprland.nvidia_sync
        {_args = ["AQ_DRM_DEVICES" "/dev/dri/${myvars.dgpu_sym_name}:/dev/dri/${myvars.igpu_sym_name}"];};

      bind = [
        # Add shortcut key for Leave Mode. Leave to main monitor for sunshine streaming
        {
          _args = [
            (lib.generators.mkLuaInline ''main_mod .. " + Y"'')
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${
                builtins.concatStringsSep "; " [
                  ''hyprctl dispatch 'hl.monitor({ output = \"${monitor_0.output}\", disabled = true })' ''
                  ''notify-send 'Hyprland' 'Leave mode: on' ''
                ]
              }")'')
            {locked = true;}
          ];
        }
        # Restore the monitors
        {
          _args = [
            (lib.generators.mkLuaInline ''main_mod .. " + SHIFT + Y"'')
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${
                builtins.concatStringsSep "; " [
                  "hyprctl reload"
                  ''notify-send 'Hyprland' 'Leave mode: off' ''
                ]
              }")'')
          ];
        }
        # Going to dock mode if has external monitor connected
        {
          _args = [
            (lib.generators.mkLuaInline ''"switch:on:Lid Switch"'')
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${
                builtins.concatStringsSep " " [
                  # Hyprland interprets commands starting with [ as window rules, change it to `test`, same as Lua
                  # Config
                  "test $(hyprctl -j monitors | jq '.[].name' | wc -w) -ne 1"
                  ''&& hyprctl dispatch 'hl.monitor({ output = \"${monitor_0.output}\", disabled = true })' ''
                ]
              }")'')
          ];
        }
        # Restore internal monitor
        {
          _args = [
            (lib.generators.mkLuaInline ''"switch:off:Lid Switch"'')
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("hyprctl reload")'')
          ];
        }
      ];
    };
  };
}

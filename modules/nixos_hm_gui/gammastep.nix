# Adjust the color temperature (& brightness) of your screen according to your surroundings. This may relieve your eyes
# fatigue if you are working in front of the screen at night. Ref: https://gitlab.com/chinstrap/gammastep
# Works on X11 & Wayland
{
  pkgs,
  lib,
  ...
}:
{
  services.gammastep = {
    enable = true;
    tray = true;
    temperature = {
      day = 6500;
      night = 4000;
    };
    # https://gitlab.com/chinstrap/gammastep/-/blob/master/gammastep.conf.sample?ref_type=heads
    settings = {
      general = {
        location-provider = "manual";
        # by default, Redshift will use the current elevation of the sun to determine whether it is daytime, night or
        # in transition (dawn/dusk)
        # dawn-time = "6:00-8:45";
        # dusk-time = "18:35-20:15";

        fade = "1"; # Gradually apply the new screen temperature/brightness over a couple of seconds

        # This is a fake brightness adjustment obtained by manipulating the gamma ramps, which means that it does not
        # reduce the backlight of the screen. Preferably only use it if your normal backlight adjustment is too
        # coarse-grained.
        # brightness-day = "1.0";
        # brightness-night = "0.8";
      };
      manual = {
        # Set geological position to Bilibili's headquarter, Shanghai, China.
        # https://www.openstreetmap.org/node/7190124016
        lat = "31.3113626";
        lon = "121.5020943";
      };
    };
  };
  xdg.configFile."gammastep/hooks/mako.sh".source = pkgs.writeShellScript "gammastep-hooks-mako" ''
    set -eufo pipefail
    case $1 in
      period-changed)
        exec ${lib.getExe pkgs.libnotify} "Gammastep" "Period changed to $3"
    esac
  '';
}

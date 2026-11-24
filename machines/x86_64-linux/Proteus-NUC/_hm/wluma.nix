{ lib, ... }: {
  services.wluma = {
    enable = true;

    settings = {
      # wluma only allows exactly one [als.*] section.
      als = {
        # time.thresholds = {
        #   "0" = "night";
        #   "7" = "dark";
        #   "9" = "dim";
        #   "11" = "normal";
        #   "13" = "bright";
        #   "16" = "normal";
        #   "18" = "dark";
        #   "20" = "night";
        # };
        webcam = {
          video = 0;
          thresholds = {
            "0" = "night";
            "15" = "dark";
            "30" = "dim";
            "45" = "normal";
            "60" = "bright";
            "75" = "outdoors";
          };
        };
      };

      output = {
        backlight = lib.singleton {
          name = "eDP-1";
          # No udev rule needed as brightness goes through logind's D-Bus SetBrightness
          path = "/sys/class/backlight/intel_backlight";
          capturer = "none";
        };
        ddcutil = lib.singleton {
          # `name` doubles as the DDC identifier (it matches
          # "Monitor: IPS:C340SCA:" from `ddcutil detect --terse`) and as the
          # substring matched against niri's wl_output description for screencopy.
          # niri 26.04 supports wlr-screencopy / ext-image-copy-capture, so
          # capturer="wayland" resolves. If wluma restart-loops with
          # "No supported Wayland protocols found", set this to "none".
          # If output matching fails, use `name = "DP-3"; identifier = "C340SCA";`.
          name = "C340SCA"; # ddcutil detect --terse
          capturer = "wayland";
        };
      };
    };
  };
}

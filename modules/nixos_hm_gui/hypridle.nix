{
  # TODO noctalia has idle management already
  # For dbus' loginctl lock/unlock
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "noctalia-shell ipc --any-display call lockScreen lock";
        before_sleep_cmd = "loginctl lock-session"; # lock before suspend.
        after_sleep_cmd = "hyprctl dispatch dpms on"; # avoid have to press a key twice to turn on the display.
      };
      listener = [
        {
          timeout = 600; # 10min
          on-timeout = "loginctl lock-session"; # lock screen when timeout has passed
        }
        {
          timeout = 630; # 10.5min
          # screen off when timeout has passed
          on-timeout = "noctalia-shell ipc --any-display call monitors off";
          # screen on when activity is detected after timeout has fired.
          # on-resume = ''hyprctl dispatch "hl.dsp.dpms({ action = 'enable' })"'';
        }
      ];
    };
  };
}

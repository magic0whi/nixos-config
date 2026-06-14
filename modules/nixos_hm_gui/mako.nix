{ pkgs, ... }:
{
  services.mako = {
    enable = true; # mako is trigged by dbus
    settings = {
      max-history = 100;
      padding = 5;
      border-radius = 8;
      max-icon-size = 48;
      default-timeout = 5000;
      layer = "overlay";
      on-button-middle = "none";
      on-button-right = "dismiss-all";
      on-notify = "exec mpv --keep-open=no ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/message.oga";
      "urgency=low".default-timeout = 2000;
      "urgency=high".default-timeout = "0";
      "category=mpd" = {
        default-timeout = 2000;
        group-by = "category";
      };
    };
  };
}

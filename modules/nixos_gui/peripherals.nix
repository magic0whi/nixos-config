{
  config,
  lib,
  myvars,
  pkgs,
  ...
}: {
  security.pam.services =
    lib.mkIf config.home-manager.users.${myvars.username}.programs.swaylock.enable {swaylock = {};};
  # Audio(PipeWire)
  environment.systemPackages = [pkgs.pulseaudio]; # Provides `pactl`, which is required by some apps (e.g. sonic-pi)

  # PipeWire is a new low-level multimedia framework. It aims to offer capture and playback for both audio and video
  # with minimal latency. It support for PulseAudio-, JACK-, ALSA- and GStreamer-based applications. PipeWire has a
  # great bluetooth support, it can be a good alternative to PulseAudio. Ref: https://nixos.wiki/wiki/PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };
  security.rtkit.enable = true; # rtkit is optional but recommended
  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  # Misc
  services = {
    printing.enable = true; # Enable CUPS to print documents.
    geoclue2.enable = true; # Enable geolocation services.
    udev.packages = with pkgs; [
      gnome-settings-daemon
      platformio # udev rules for platformio
      openocd # Required by paltformio, ref: https://github.com/NixOS/nixpkgs/issues/224895
      openfpgaloader
    ];
    # A key remapping daemon for Linux, ref: https://github.com/rvaiya/keyd
    keyd = {
      enable = true;
      keyboards.default.settings = {
        main = {
          # Overloads the capslock key to function as both escape (when tapped) and control (when held)
          capslock = "overload(control, esc)";
          esc = "capslock";
        };
      };
    };
  };
}

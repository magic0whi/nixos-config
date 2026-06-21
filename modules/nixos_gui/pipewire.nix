{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.pulseaudio ]; # Provides `pactl`, which is required by some apps (e.g. sonic-pi)

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
  # rtkit allows Pipewire to use the realtime scheduler for increased performance.
  security.rtkit.enable = true;
}

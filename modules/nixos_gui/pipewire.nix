{ const, pkgs, ... }:
{
  environment.persistence."/persistent".users.${const.username}.directories = [ ".config/pulse" ];

  environment.systemPackages = [
    pkgs.pulseaudio # Provides `pactl`, which is required by some apps (e.g. sonic-pi)
    # `jack.enable` is deprecated (global LD_LIBRARY_PATH), run JACK apps via `pw-jack <app>` instead
    # pkgs.pipewire.jack
  ];

  # https://nixos.wiki/wiki/PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  security.rtkit.enable = true; # rtkit lets Pipewire use the real-time scheduler for lower latency.
}

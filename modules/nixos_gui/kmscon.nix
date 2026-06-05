{ config, ... }:
{
  hardware.graphics.enable = config.services.kmscon.config.hwaccel;
  services.kmscon = {
    # Kmscon is a KMS/DRI-based userspace virtual terminal implementation. It supports a richer feature set than the
    # standard linux console VT, including full unicode support, and with a DRM available video card it should be much
    # faster.
    # Ref: https://wiki.archlinux.org/title/KMSCON
    # NOTE: This will make `hardware.graphics.enable = true`, which installs mesa packages (~985.48MiB as 12/02/25)
    enable = true;
    config.hwaccel = true; # Whether to use 3D hardware acceleration to render the console.
    extraOptions = "--term xterm-256color";
  };
}

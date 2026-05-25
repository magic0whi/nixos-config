{ myvars, ... }:
{
  services.kmscon = {
    # https://wiki.archlinux.org/title/KMSCON
    # Use Kmscon as the virtual console instead of getty. Kmscon is a KMS/DRI-based userspace virtual terminal
    # implementation. It supports a richer feature set than the standard linux console VT, including full unicode
    # support, and when the video card supports DRM should be much faster.
    # NOTE: This will make `hardware.graphics.enable = true`, which installs mesa packages (~985.48MiB as 12/02/25)
    enable = true;
    fonts = [ { inherit (myvars.monospace) name package; } ];
    hwRender = true; # Whether to use 3D hardware acceleration to render the console.
    extraOptions = "--term xterm-256color";
    extraConfig = "font-size=12";
  };
}

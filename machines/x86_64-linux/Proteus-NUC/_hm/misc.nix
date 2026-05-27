{ config, ... }:
{
  programs.mpv.profiles.common.vulkan-device =
    if config.wayland.windowManager.hyprland.nvidia_sync then
      "NVIDIA GeForce RTX 3070 Laptop GPU"
    else
      "Intel(R) UHD Graphics (TGL GT1)";
}

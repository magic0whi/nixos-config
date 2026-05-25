_: {
  ## BEGIN aerospace.nix
  programs.aerospace.settings.workspace-to-monitor-force-assignment = {
    "7" = [ "C340SCA" ];
    "8" = [ "C340SCA" ];
    "9" = [ "RTK UHD HDR" ];
    "0" = [ "RTK UHD HDR" ];
  };
  ## END aerospace.nix
  ## BEGIN mpv.nix
  programs.mpv.profiles.common = {
    vulkan-device = "Apple M4 Pro";
    ao = "avfoundation";
  };
  ## END mpv.nix
}

{
  mylib,
  pkgs,
  ...
}: {
  imports = mylib.scan_path ./.;
  home.packages = with pkgs; [chezmoi];
  programs = {
    aerospace.settings.workspace-to-monitor-force-assignment = {
      "7" = ["C340SCA"];
      "8" = ["C340SCA"];
      "9" = ["RTK UHD HDR"];
      "0" = ["RTK UHD HDR"];
    };
    mpv.profiles.common = {
      vulkan-device = "Apple M4 Pro";
      ao = "avfoundation";
    };
  };
}

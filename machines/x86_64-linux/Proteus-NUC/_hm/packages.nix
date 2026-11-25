{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (nvtopPackages.intel.override { nvidia = true; })
    minicom # embedded development
    chezmoi
    qpdf
    act # Run your GitHub Actions locally
    witr
    intel-undervolt

    nixpaks.wechat
  ];
  programs.antigravity-cli.enable = true;
  programs.obsidian.enable = true;
}

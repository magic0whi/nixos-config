{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (nvtopPackages.intel.override { nvidia = true; })
    minicom # embedded development
    chezmoi
    libreoffice
    qpdf
    act # Run your GitHub Actions locally
    gemini-cli
    witr
  ];
}

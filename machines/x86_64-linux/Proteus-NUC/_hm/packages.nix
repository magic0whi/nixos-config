{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (nvtopPackages.intel.override { nvidia = true; })
    minicom # embedded development
    chezmoi
    libreoffice
    qpdf
    act # Run your GitHub Actions locally
    witr
    intel-undervolt
  ];
  home.persistence."/persistent".directories = [ ".config/libreoffice" ];
  programs.antigravity-cli.enable = true;
  programs.obsidian.enable = true;
}

_: {
  ## BEGIN neovim.nix
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };
  ## END neovim.nix
  ## BEGIN direnv.nix
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  ## END direnv.nix
  ## BEGIN latex.nix
  programs.tex-fmt = {
    enable = true;
    settings = {
      wraplen = 120;
      wrapmin = 120;
      format-tables = true;
    };
  };
  ## END latex.nix
  ## BEGIN pip.nix
  # Use mirror for pip install
  xdg.configFile."pip/pip.conf".text = ''
    [global]
    index-url = https://mirror.nju.edu.cn/pypi/web/simple
    format = columns
  '';
  ## END pip.nix
}

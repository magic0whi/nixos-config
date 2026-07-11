{ lib, pkgs, ... }:
{
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
  # programs.tex-fmt = {
  #   enable = true;
  #   settings = {
  #     wraplen = 120;
  #     wrapmin = 120;
  #     format-tables = true;
  #   };
  # };
  home.file.".indentconfig.yaml".text = ''
    paths:
      - /home/proteus/.config/latexindent/mysettings.yaml
  '';
  xdg.configFile."latexindent/mysettings.yaml".text = ''
    defaultIndent: "  "
    modifyLineBreaks:
      textWrapOptions:
        columns: 120
    # Format the witharrows environment
    lookForAlignDelims:
      DispWithArrows: 1
      DispWithArrows*: 1

  '';
  ## END latex.nix
  ## BEGIN pip.nix
  # Use mirror for pip install
  xdg.configFile."pip/pip.conf".text = lib.generators.toINI { } {
    global = {
      index-url = "https://mirror.nju.edu.cn/pypi/web/simple";
      format = "columns";
    };
  };
  ## END pip.nix
  ## START lsp.nix
  home.packages =
    (with pkgs; [
      bash-language-server
      vscode-json-languageserver
      yaml-language-server
      nixfmt-rs
      nixd
      taplo # TOML LSP
      kdlfmt
    ])
    # NOTE: Requires bootstrap GHC
    ++ lib.optionals (!pkgs.stdenv.hostPlatform.isRiscV64) [ pkgs.marksman ];
  ## END lsp.nix
}

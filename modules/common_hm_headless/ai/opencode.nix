{ config, mylib, ... }:
{
  home.persistence."/persistent".directories =
    let
      xdg = mylib.xdgRelTo config.home.homeDirectory config.xdg;
    in
    [
      "${xdg.configHome}/opencode"
      "${xdg.dataHome}/opencode"
      "${xdg.stateHome}/opencode"
    ];

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    context = builtins.readFile ./AGENTS.md;
    skills = {
      git-commit = ./_skills/git-commit.md;
      nixos-search = ./_skills/nixos-search.md;
      noogle = ./_skills/noogle.md;
    };
  };
}

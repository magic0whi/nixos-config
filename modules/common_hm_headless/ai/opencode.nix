{ xdgRel, ... }:
{
  home.persistence."/persistent".directories = [
    "${xdgRel.configHome}/opencode"
    "${xdgRel.dataHome}/opencode"
    "${xdgRel.stateHome}/opencode"
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

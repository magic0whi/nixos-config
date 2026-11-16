{
  home.persistence."/persistent".directories = [
    ".config/opencode"
    ".local/share/opencode"
    ".local/state/opencode"
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

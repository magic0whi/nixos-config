{
  agent-skills,
  xdgRel,
  ...
}:
{
  home.persistence."/persistent".directories = [
    "${xdgRel.configHome}/opencode"
    "${xdgRel.dataHome}/opencode"
    "${xdgRel.stateHome}/opencode"
  ];

  programs.opencode = {
    enable = true;
    # NOTE:
    # OpenCode 2 rewrites cli.json/opencode.json from the TUI, replacing the managed
    # symlinks with regular files; the next switch then fails backing them up.
    # So avoid operations like toggle sidebar
    enableMcpIntegration = true;
    context = builtins.readFile (agent-skills + "/AGENTS.md");
    skills = agent-skills + "/skills";
    cli.debug.turn_tokens = "verbose";
  };

  # OpenCode auto-discovers plugins in `$XDG_CONFIG_HOME/opencode/plugins`.
  xdg.configFile."opencode/plugins" = {
    source = agent-skills + "/plugins";
    recursive = true;
  };
}

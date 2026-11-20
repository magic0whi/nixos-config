{ agent-skills, xdgRel, ... }:
{
  home.persistence."/persistent".directories = [
    "${xdgRel.configHome}/opencode"
    "${xdgRel.dataHome}/opencode"
    "${xdgRel.stateHome}/opencode"
  ];

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    context = builtins.readFile (agent-skills + "/AGENTS.md");
    skills = agent-skills + "/skills";
  };
}

{
  config,
  const,
  lib,
  ...
}:
{
  sops.secrets.claude-code_token.sopsFile = const.secretsDir + "/services/claude-code.sops.yaml";

  # MCP header secrets (sops + env exports) live in ../mcp.nix, shared with opencode.

  # Move CC's global state file `~/.claude.json` into ~/.claude/
  home.sessionVariables.CLAUDE_CONFIG_DIR = config.programs.claude-code.configDir;
  home.persistence."/persistent".directories = [ ".claude" ];

  programs.zsh.initContent = lib.mkAfter (
    with config.sops.secrets;
    ''
      if [[ -r ${claude-code_token.path} ]]; then
        export CLAUDE_CODE_OAUTH_TOKEN="$(<"${claude-code_token.path}")"
      fi
    ''
  );

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
    context = ../AGENTS.md; # ~/.claude/CLAUDE.md
    # Claude Code only expands ${VAR} in .mcp.json headers (not the shared
    # {env:VAR} syntax from ../mcp.nix), so override the shared remote headers
    # here; these entries replace the shared ones (merge is per-server, Claude
    # Code takes precedence). Secrets stay out of the Nix store via runtime
    # expansion; the vars themselves are exported in ../mcp.nix.
    mcpServers = {
      context7 = {
        type = "http";
        url = "https://mcp.context7.com/mcp";
        headers.CONTEXT7_API_KEY = "\${MCP_CONTEXT7_KEY}";
      };
      github = {
        type = "http";
        url = "https://api.githubcopilot.com/mcp";
        headers.Authorization = "Bearer \${MCP_GITHUB_KEY}";
      };
    };
    # ~/.claude/settings.json
    settings = {
      model = "opus";
      effortLevel = "high";
      feedbackSurveyRate = 0;
      tui = "fullscreen";
      enabledPlugins."marimo-pair@marimo-pair" = true;
      extraKnownMarketplaces.marimo-pair.source = {
        source = "github";
        repo = "marimo-team/marimo-pair";
      };
      env = {
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
        DISABLE_TELEMETRY = "1";
      };
    };
  };
}

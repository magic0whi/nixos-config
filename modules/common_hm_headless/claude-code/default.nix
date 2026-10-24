{
  config,
  const,
  lib,
  ...
}:
{
  sops.secrets = {
    claude_code_oauth_token.sopsFile = "${const.secretsDir}/common_hm.sops.yaml";
    github_mcp_pat.sopsFile = "${const.secretsDir}/common_hm.sops.yaml";
  };

  programs.zsh.initContent = lib.mkAfter (
    with config.sops.secrets;
    ''
      if [[ -r ${claude_code_oauth_token.path} ]]; then
        export CLAUDE_CODE_OAUTH_TOKEN="$(<${claude_code_oauth_token.path})"
      fi
      if [[ -r ${github_mcp_pat.path} ]]; then
        export GITHUB_MCP_PAT="$(<${github_mcp_pat.path})"
      fi
    ''
  );
  programs.claude-code = {
    enable = true;
    context = ./CLAUDE.md; # ~/.claude/CLAUDE.md
    # ~/.claude.json mcpServers
    mcpServers = {
      context7 = {
        type = "http";
        url = "https://mcp.context7.com/mcp";
        # Optional: raise rate limits with an API key from https://context7.com/dashboard.
        # The generated config lands in the world-readable Nix store, so don't inline the
        # key here — set it out-of-band, e.g.:
        #   claude mcp add --transport http context7 https://mcp.context7.com/mcp \
        #     --header "CONTEXT7_API_KEY: <key>"
      };
      github = {
        type = "http";
        url = "https://api.githubcopilot.com/mcp";
        # GitHub's MCP server doesn't support OAuth dynamic client registration, so
        # authenticate with a PAT. Claude Code expands ${VAR} at runtime, keeping the
        # token out of the Nix store.
        headers.Authorization = "Bearer \${GITHUB_MCP_PAT}";
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

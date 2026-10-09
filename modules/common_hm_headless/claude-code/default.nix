{
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

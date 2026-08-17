{
  programs.claude-code = {
    enable = true;
    context = ./CLAUDE.md; # ~/.claude/CLAUDE.md
    # ~/.claude/settings.json
    settings = {
      model = "opus";
      effortLevel = "high";
      feedbackSurveyRate = 0;
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

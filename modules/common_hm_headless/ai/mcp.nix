{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets = {
    mcp_context7_key = { };
    mcp_github_key = { };
    mcp_forgejo_access_token = { };
  };

  programs.zsh.initContent = lib.mkAfter (
    with config.sops.secrets;
    ''
      if [[ -r ${mcp_context7_key.path} ]]; then
        export MCP_CONTEXT7_KEY="$(<${mcp_context7_key.path})"
      fi
      if [[ -r ${mcp_github_key.path} ]]; then
        export MCP_GITHUB_KEY="$(<${mcp_github_key.path})"
      fi
    ''
  );

  programs.mcp = {
    enable = true;
    servers = {
      context7 = {
        url = "https://mcp.context7.com/mcp";
        headers.CONTEXT7_API_KEY = "{env:MCP_CONTEXT7_KEY}";
      };
      github = {
        url = "https://api.githubcopilot.com/mcp";
        headers.Authorization = "Bearer {env:MCP_GITHUB_KEY}";
      };
      forgejo = {
        command = "${lib.getExe pkgs.forgejo-mcp}";
        args = [
          "--transport"
          "stdio"
          "--url"
          "https://git.proteus.eu.org/"
        ];
        env.FORGEJO_ACCESS_TOKEN.file = config.sops.secrets.mcp_forgejo_access_token.path;
      };
    };
  };
}

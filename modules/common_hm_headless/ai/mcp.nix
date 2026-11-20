{
  config,
  const,
  lib,
  mypkg,
  pkgs,
  ...
}:
{
  sops.secrets =
    let
      sopsFile = const.secretsDir + "/services/mcp.sops.yaml";
    in
    {
      mcp_context7_key = { inherit sopsFile; };
      mcp_github_key = { inherit sopsFile; };
      mcp_forgejo_access_token = { inherit sopsFile; };
      mcp_paperless_api_key = { inherit sopsFile; };
      mcp_exa_key = { inherit sopsFile; };
      mcp_firecrawl-mcp_oidc_client_secret = { inherit sopsFile; };
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
      if [[ -r ${mcp_exa_key.path} ]]; then
        export MCP_EXA_KEY="$(<${mcp_exa_key.path})"
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
      anki.url = "http://127.0.0.1:3141/";
      firecrawl = {
        command = toString (
          pkgs.writeShellScript "firecrawl-mcp-authelia" ''
            set -euo pipefail

            export FIRECRAWL_API_KEY="$(
              ${lib.getExe mypkg.fetch-authelia-token} \
                --client-id firecrawl-mcp \
                --client-secret-file ${lib.escapeShellArg config.sops.secrets.mcp_firecrawl-mcp_oidc_client_secret.path} \
                --resource ${lib.escapeShellArg "https://firecrawl.${const.domain}"} \
                --auth-url ${lib.escapeShellArg "https://auth.${const.domain}"}
            )"

            exec ${lib.getExe pkgs.firecrawl-mcp}
          ''
        );
        env.FIRECRAWL_API_URL = "https://firecrawl.${const.domain}";
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
      paperless = {
        command = lib.getExe mypkg.paperless-mcp;
        env = {
          PAPERLESS_URL = "https://paperless.${const.domain}";
          PAPERLESS_PUBLIC_URL = "https://paperless.${const.domain}";
          PAPERLESS_API_KEY.file = config.sops.secrets.mcp_paperless_api_key.path;
          # Restrict filesystem-mode uploads via `post_document` (colon-separated)
          PAPERLESS_MCP_UPLOAD_PATHS = lib.concatStringsSep ":" [
            "${config.home.homeDirectory}/Downloads"
            "${config.home.homeDirectory}/Documents"
            "/tmp"
          ];
        };
      };
      exa = {
        url = "https://mcp.exa.ai/mcp?tools=web_search_exa,web_fetch_exa,web_search_advanced_exa";
        headers.Authorization = "Bearer {env:MCP_EXA_KEY}";
      };
    };
  };
}

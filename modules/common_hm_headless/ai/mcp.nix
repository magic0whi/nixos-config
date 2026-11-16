{
  config,
  const,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets = {
    mcp_context7_key = { };
    mcp_github_key = { };
    mcp_forgejo_access_token = { };
    firecrawl_mcp_oidc_client_secret.sopsFile = "${const.secretsDir}/common.sops.yaml";
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
      firecrawl = {
        command = toString (
          pkgs.writeShellScript "firecrawl-mcp-authelia" ''
            set -euo pipefail

            echo "Fetching fresh token from Authelia via client_credentials..." >&2

            RESPONSE="$(${pkgs.curl}/bin/curl -fsX POST \
                -H 'Content-Type: application/x-www-form-urlencoded' \
                -u "firecrawl-mcp:$(<${config.sops.secrets.firecrawl_mcp_oidc_client_secret.path})" \
                -d 'grant_type=client_credentials' \
                -d 'scope=authelia.bearer.authz' \
                -d 'audience=https://firecrawl.${const.domain}' \
                'https://auth.${const.domain}/api/oidc/token')"

            export FIRECRAWL_API_KEY="$(printf '%s' "$RESPONSE" | ${pkgs.jq}/bin/jq -er '.access_token')"
            unset RESPONSE

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
    };
  };
}

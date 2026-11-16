{ const, lib, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc = {
    # Ref: https://www.authelia.com/configuration/identity-providers/openid-connect/provider/#custom
    lifespans.custom.firecrawl-mcp.grants.client_credentials.access_token = "24h";
    clients = lib.singleton {
      client_id = "firecrawl-mcp";
      client_name = "Firecrawl MCP";
      client_secret = "$pbkdf2-sha512$310000$5yFlgtqrQL4HqBKlNT1rdQ$mVnY7vLe/G1wYWzgVX75Jg8L6vlOaQmDZ1Ipcc6KN1JvX4.Dnu8v0FxPUgqNyG/QQ1iCC3O2.k3WZUTd3/ifng";
      grant_types = [ "client_credentials" ];
      scopes = [ "authelia.bearer.authz" ];
      audience = [ "https://firecrawl.${const.domain}" ];
      token_endpoint_auth_method = "client_secret_basic";
      lifespan = "firecrawl-mcp";
    };
  };
}

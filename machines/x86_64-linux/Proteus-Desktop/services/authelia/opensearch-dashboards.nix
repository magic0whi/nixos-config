{ lib, const, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc = {
    claims_policies = {
      # https://www.authelia.com/integration/openid-connect/openid-connect-1.0-claims/#restore-functionality-prior-to-claims-parameter
      opensearch_policy.id_token = [
        "preferred_username"
        "name"
        "email"
        "groups"
      ];
    };
    clients = lib.singleton {
      client_id = "opensearch-dashboards";
      client_name = "OpenSearch Dashboards";
      client_secret = "$pbkdf2-sha512$310000$ABGWSADqYSUeeF5ZDQlhNg$c4aee7uOMUwHOHv5myhhu.VNxwEBhBnNUAI1DjutkmICQ33W1QnJA0k8cQkpEOubCa5jGrFC.e6Un4QuKnu0YQ";
      redirect_uris = [ "https://opensearch-dashboards.${const.domain}/auth/openid/login" ];
      scopes = [
        "openid"
        "profile"
        "email"
        "groups"
      ];
      token_endpoint_auth_method = "client_secret_post";
      claims_policy = "opensearch_policy"; # https://github.com/opensearch-project/security/issues/2040
    };
  };
}

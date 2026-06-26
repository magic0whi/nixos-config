{ lib, const, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc.clients = lib.singleton {
    client_id = "plane";
    client_name = "Plane";
    client_secret = "$pbkdf2-sha512$310000$js.q7nxEc0JzjQN3NRyyrA$0F2fFhnC3HJspJUhFSp56F4Rl0PhzaYV.J9TytIfxZfiE7GDAuHIYKxSa262k/rf7d/vgOVHVa5a9C9P1YIYRg";
    redirect_uris = [
      "https://plane.${const.domain}/auth/gitea/callback"
      "https://plane.${const.domain}/auth/gitea/callback/"
    ];
    scopes = [
      "openid"
      "email"
      "profile"
    ];
    token_endpoint_auth_method = "client_secret_post";
  };
}

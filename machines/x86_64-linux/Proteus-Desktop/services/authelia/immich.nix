{ lib, const, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc.clients = lib.singleton {
    client_id = "immich";
    client_name = "Immich";
    client_secret = "$pbkdf2-sha512$310000$JUEH012JXQCrSrfFFfk0WQ$aDVGFs8q.rusT89Kkd.d0i/HggzaGRjEXCl5XbOBSBRpQNqty5rVK/UoJJmILPJUCmd5uYZPHhiHu6HWtAE8BQ";
    redirect_uris = [
      "https://immich.${const.domain}/auth/login"
      "https://immich.${const.domain}/user-settings"
      "app.immich:///oauth-callback" # Crucial for the Immich Mobile App
    ];
    scopes = [
      "openid"
      "email"
      "profile"
    ];
    token_endpoint_auth_method = "client_secret_post";
  };
}

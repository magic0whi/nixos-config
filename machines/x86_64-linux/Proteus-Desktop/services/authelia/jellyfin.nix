{ lib, const, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc.clients = lib.singleton {
    client_id = "jellyfin";
    client_name = "Jellyfin";
    client_secret = "$pbkdf2-sha512$310000$OCHTcrIFbKQm01kTARfhRw$Lo2MFk28quOgOO.Kl29eXtS62ELRjU9XqNnN0eKK9qXvFylPHv9xdKsbLqMrHgqHAS8fHjVSE9lREuDkle1lZg";
    require_pkce = true;
    pkce_challenge_method = "S256";
    redirect_uris = [ "https://jellyfin.${const.domain}/sso/OID/redirect/authelia" ];
    scopes = [
      "openid"
      "profile"
      "groups"
    ];
    token_endpoint_auth_method = "client_secret_post";
  };
}

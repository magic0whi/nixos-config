{ lib, const, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc.clients = lib.singleton {
    client_id = "paperless";
    client_name = "Paperless-ngx";
    client_secret = "$pbkdf2-sha512$310000$utOYjxWkjgXCc1TIfgg5ZQ$KA7m4g/DPTj17MWYa2nOaunrF6ZXSBlDoddd5xuCXY5cVRhgHuZ7hObedPFwRhnc772ngzbTNqy1WhANklh1CQ";
    redirect_uris = [ "https://paperless.${const.domain}/accounts/oidc/authelia/login/callback/" ];
    scopes = [
      "openid"
      "profile"
      "email"
    ];
    token_endpoint_auth_method = "client_secret_post";
  };
}

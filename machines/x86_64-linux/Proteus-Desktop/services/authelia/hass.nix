{ lib, const, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc.clients = lib.singleton {
    client_id = "hass";
    client_name = "Home Assistant";
    client_secret = "$pbkdf2-sha512$310000$L/jbJ7m.3.Xpo0oveApPUw$BFNopAMji6HRC6u7qDJDDz2bp7DWFt76IKPxURPAoqFNcbFU3/IRks2wibnh4IOjSpuVmHBtT2qAU1bu1ugldw";
    require_pkce = true;
    pkce_challenge_method = "S256";
    redirect_uris = [ "https://hass.${const.domain}/auth/oidc/callback" ];
    scopes = [
      "openid"
      "profile"
      "groups"
    ];
    token_endpoint_auth_method = "client_secret_post";
  };
}

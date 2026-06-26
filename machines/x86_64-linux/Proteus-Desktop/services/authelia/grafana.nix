{ lib, const, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc.clients = lib.singleton {
    client_id = "grafana";
    client_name = "Grafana";
    client_secret = "$pbkdf2-sha512$310000$Pa88imsImH54Txr28109eg$KhvhekOpdjSXC4A60RBpAzeyDj7824/twTeT52bYArZL2RtzkBU49g.0XNp9MMStsM8yJN.JXZeBkOabc07mrA";
    require_pkce = true;
    pkce_challenge_method = "S256";
    redirect_uris = [ "https://grafana.${const.domain}/login/generic_oauth" ];
    scopes = [
      "openid"
      "profile"
      "groups"
      "email"
    ];
  };
}

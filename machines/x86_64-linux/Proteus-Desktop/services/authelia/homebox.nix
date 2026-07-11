{ lib, const, ... }:
{
  # Ref:
  # - https://www.authelia.com/integration/openid-connect/clients/homebox/
  # - https://homebox.software/en/quick-start/configure/oidc/
  services.authelia.instances.main.settings.identity_providers.oidc.clients = lib.singleton {
    client_id = "homebox";
    client_name = "HomeBox";
    client_secret = "$pbkdf2-sha512$310000$94K/tFC1BtCkEEkASPmnzg$PHiafbx3pREdza5D3rwbgiNV69HXIKW0XrPWFlMuSefKKrRtvgPfKqsYleRsFN4qU8RX/lwqAwFtFqytk2h.HA";
    require_pkce = true;
    pkce_challenge_method = "S256";
    redirect_uris = [ "https://homebox.${const.domain}/api/v1/users/login/oidc/callback" ];
    scopes = [
      "openid"
      "groups"
      "email"
      "profile"
    ];
  };
}

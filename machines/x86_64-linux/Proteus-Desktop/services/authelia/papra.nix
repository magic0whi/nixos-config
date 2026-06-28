{ lib, const, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc.clients = lib.singleton {
    client_id = "papra";
    client_name = "Papra";
    client_secret = "$pbkdf2-sha512$310000$3KSvvBJnoLyJDoKDBIBcZQ$dMQmccJ6Y4hrj.tv.dD3KFzLcsPCsMNRZFTpHUiInVcSX0eBR5T6jemXfcUaob9PsbgHBwRNCjtXiBNl6lOc7g";
    redirect_uris = [ "https://papra.${const.domain}/api/auth/oauth2/callback/authelia" ];
    # authorization_policy = "one_factor";
    token_endpoint_auth_method = "client_secret_post";
  };
}

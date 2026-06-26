{ lib, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc.clients = lib.singleton {
    client_id = "niks3_yajuusexnpai";
    client_name = "Niks3 Client Credentials Test";
    client_secret = "$pbkdf2-sha512$310000$3oNLFhvo3pg1e/YTke0dQw$VOx0ZqszL4IFhY5bMaeEwQOicTq4.egK3HaPrxG5BRoQfv.FPT35EKZW9ZPkEtj4LYy2wJR2BQM3DCdXxRLaBg";
    grant_types = [ "client_credentials" ];
    # Niks3 requires a signed JWT, force Authelia to issue a signed JWT access token instead of access token only
    access_token_signed_response_alg = "RS256";
    audience = [ "niks3" ]; # Whitelist the requested audience
  };
}

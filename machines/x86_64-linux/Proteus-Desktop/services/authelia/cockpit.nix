{ lib, const, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc.clients = lib.singleton {
    client_id = "cockpit";
    client_name = "Cockpit";
    # This client has no secret
    public = true;
    # Implicit flow requires no client secret
    grant_types = [ "implicit" ];
    response_types = [ "token" ];
    # Response_mode is fragment to pass the access token back via the URL
    response_modes = [ "fragment" ];
    redirect_uris = [ "https://cockpit-desktop.${const.domain}" ];
    scopes = [
      "openid"
      "profile"
      "email"
      "groups"
    ];
  };
}

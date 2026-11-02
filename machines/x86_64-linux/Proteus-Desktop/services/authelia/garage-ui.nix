{ lib, const, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc.clients =
    let
      mk_client = name: secret: {
        client_id = "garage-ui-${lib.toLower name}";
        client_name = "Garage UI (${name})";
        client_secret = secret;
        redirect_uris = map (hostname: "https://${hostname}.garage.${const.domain}/auth/oidc/callback") (
          const.networking.findAllHostContains ".garage"
        );
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
      };
    in
    [
      (mk_client "Desktop" "$pbkdf2-sha512$310000$cI9ez0W8/AFpiYwf2sKz6A$hM76ibvvoKdO/b8K9jVckvgAvJDPCxfiE17l4KqO8d0ipsMFjWQ7OIPeMusN98k5aiPsg5Sv47DcHL2KY5/bWQ")
      (mk_client "GCP" "$pbkdf2-sha512$310000$d4XM/yWTS2G.tW1B8s.svQ$smfUUsdaR7vSUYnZZaLWtQLcptG8dS8S0QSExmJkhTW7uEne.OjHd7/JyUASAX1M.CE6OOqwf7Uep7bSBlLegw")
    ];
}

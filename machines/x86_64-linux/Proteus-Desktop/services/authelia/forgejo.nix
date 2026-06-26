{ lib, const, ... }:
{
  services.authelia.instances.main.settings.identity_providers.oidc.clients = lib.singleton {
    client_id = "forgejo";
    client_name = "Forgejo";
    client_secret = "$pbkdf2-sha512$310000$hHi.uSu97kUzfh.X9ijhXA$.IL0RMznXtdwXGTYq9eKV.83nIXI0glK7v.IaFYu5xVpweng.zo5L5PpuC6aQgY6R9ROgSFQrHbve3LK50j/yg";
    redirect_uris = [ "https://git.${const.domain}/user/oauth2/Authelia/callback" ];
    require_pkce = true;
    pkce_challenge_method = "S256"; # effectively enables the require_pkce
  };
}

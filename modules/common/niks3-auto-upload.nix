{ const, ... }:
{
  sops.secrets.niks3_client_secret = { };
  services.niks3-auto-upload = {
    enable = true;
    serverUrl = "https://niks3.${const.domain}";
  };
}

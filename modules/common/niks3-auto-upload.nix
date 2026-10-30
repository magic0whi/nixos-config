{ const, ... }:
{
  sops.secrets.niks3_client_secret_yajuusexnpai.sopsFile = "${const.secretsDir}/common.sops.yaml";
  services.niks3-auto-upload = {
    enable = true;
    serverUrl = "https://niks3.${const.domain}";
  };
}

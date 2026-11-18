{ const, config, ... }:
{
  sops.secrets.niks3_api_token.sopsFile = "${const.secretsDir}/${const.networking.findFirstHostBySubdomain "niks3"}_shared.sops.yaml";
  services.niks3-auto-upload = {
    enable = true;
    serverUrl = "https://niks3.${const.domain}";
    authTokenFile = config.sops.secrets.niks3_api_token.path;
  };
}

{
  mySecrets,
  const,
  config,
  ...
}:
{
  sops.secrets.niks3_api_token.sopsFile = mySecrets + "/services/niks3_shared.sops.yaml";
  services.niks3-auto-upload = {
    enable = true;
    serverUrl = "https://niks3.${const.domain}";
    authTokenFile = config.sops.secrets.niks3_api_token.path;
  };
}

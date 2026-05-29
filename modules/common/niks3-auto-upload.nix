{ config, myvars, ... }:
{
  sops.secrets.niks3-auto-upload_api_token =
    let
      restartUnits = [
        "niks3-auto-upload.service"
        "niks3-auto-upload.socket"
      ];
    in
    {
      key = "niks3_api_token";
      sopsFile = "${myvars.secretsDir}/common.sops.yaml";
      inherit restartUnits;
    };
  services.niks3-auto-upload = {
    enable = true;
    serverUrl = "https://niks3.${myvars.domain}";
    authTokenFile = config.sops.secrets.niks3-auto-upload_api_token.path;
  };
}

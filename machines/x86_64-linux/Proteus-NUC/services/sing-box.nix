{
  config,
  myvars,
  ...
}:
{
  sops.secrets."sb_client_linux.json" = {
    sopsFile = "${myvars.secretsDir}/sb_client_linux.json.sops";
    format = "binary";
    restartUnits = [ "sing-box.service" ];
  };
  services.sing-box = {
    enable = true;
    settings = {
      _secret = config.sops.secrets."sb_client_linux.json".path;
      quote = false;
    };
  };
}

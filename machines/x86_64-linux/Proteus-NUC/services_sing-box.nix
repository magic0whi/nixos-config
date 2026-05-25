{
  config,
  myvars,
  ...
}:
{
  sops.secrets."sb_client_linux.json" = {
    sopsFile = "${myvars.secrets_dir}/sb_client_linux.json.sops";
    format = "binary";
    restartUnits = [ "sing-box.service" ];
  };
  services.sing-box = {
    enable = true;
    configFile = config.sops.secrets."sb_client_linux.json".path;
  };
}

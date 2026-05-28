{
  config,
  myvars,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [ 443 ]; # Reality
  sops.secrets."sb_Proteus-NixOS-1.json" = {
    sopsFile = "${myvars.secretsDir}/sb_Proteus-NixOS-1.json.sops";
    format = "binary";
    restartUnits = [ "sing-box.service" ];
  };
  services.sing-box.enable = true;
  services.sing-box.settings = {
    _secret = config.sops.secrets."sb_Proteus-NixOS-1.json".path;
    quote = false;
  };
}

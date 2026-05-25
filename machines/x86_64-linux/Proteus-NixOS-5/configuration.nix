{
  config,
  myvars,
  ...
}:
{
  time.timeZone = "Asia/Hong_Kong";
  boot.kernelParams = [
    "console=ttyS0,115200"
    "earlyprintk=ttyS0,115200"
    "consoleblank=0"
    "intel_iommu=off"
  ];
  services.traffic-quota.enable = true;
  ## BEGIN sing-box.nix
  sops.secrets."sb_Proteus-NixOS-1.json" = {
    sopsFile = "${myvars.secrets_dir}/sb_Proteus-NixOS-1.json.sops";
    format = "binary";
    restartUnits = [ "sing-box.service" ];
  };
  networking.firewall.allowedTCPPorts = [ 443 ]; # Reality
  services.sing-box.enable = true;
  services.sing-box.configFile = config.sops.secrets."sb_Proteus-NixOS-1.json".path;
  ## END sing-box.nix
  boot.binfmt.emulatedSystems = [ "riscv64-linux" ]; # Cross compilation
}

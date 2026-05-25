{
  config,
  myvars,
  ...
}:
{
  time.timeZone = "Asia/Shanghai";
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.systemd-boot.enable = false;
  boot.kernelParams = [
    "net.ifnames=0"
    "consoleblank=600"
    "console=tty0"
    "console=ttyS0,115200n8"
    "noibrs"
    # "crashkernel=0M-1G:0M,1G-4G:192M,4G-128G:384M,128G-:512M"
  ];
  networking.nameservers = [
    "223.5.5.5"
    "8.8.8.8"
  ];
  services.traffic-quota.enable = true;
  ## BEGIN sing-box.nix
  ## BEGIN sing-box.nix
  sops.secrets."sb_Proteus-NixOS-6.json" = {
    sopsFile = "${myvars.secrets_dir}/sb_Proteus-NixOS-6.json.sops";
    format = "binary";
    restartUnits = [ "sing-box.service" ];
  };
  networking.firewall.allowedTCPPorts = [ 443 ]; # Reality
  services.sing-box.enable = true;
  services.sing-box.configFile = config.sops.secrets."sb_Proteus-NixOS-6.json".path;
  ## END sing-box.nix
  boot.binfmt.emulatedSystems = [ "riscv64-linux" ]; # Cross compilation
}

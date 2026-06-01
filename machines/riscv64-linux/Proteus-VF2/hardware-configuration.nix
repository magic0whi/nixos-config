{
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # disko will take care of filesystems.*, swapDevices, boot.resumeDevice, boot.initrd.luks.devices

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = "riscv64-linux";
}

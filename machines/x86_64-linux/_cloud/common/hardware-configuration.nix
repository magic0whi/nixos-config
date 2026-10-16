{
  lib,
  modulesPath,
  ...
}:
{
  # Run `nixos-generate-config --show-hardware-config` to show
  # Shared across cloud providers; per-provider extras live in <provider>/_common
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "virtio_scsi"
    "sd_mod"
  ];
  boot.kernelParams = [
    "console=ttyS0,115200"
    "earlyprintk=ttyS0,115200"
    "consoleblank=0"
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = "x86_64-linux";
}

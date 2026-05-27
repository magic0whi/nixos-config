{
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/cd-dvd/iso-image.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "uas"
    "sd_mod"
  ];
  boot.kernelParams = [
    "mitigations=off"
    "bgrt_disable"
  ];

  # disko will take care of filesystems.*, swapDevices, boot.resumeDevice, boot.initrd.luks.devices

  networking.useDHCP = true;
  networking.hostId = "5736070c"; # ZFS requires this

  nixpkgs.hostPlatform = "x86_64-linux";
}

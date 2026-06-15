{
  config,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "uas"
    "sd_mod"
  ];
  boot.initrd.systemd.enable = true; # ZFS snapshots auto rollback; Hibernation

  # boot.extraModulePackages = [config.boot.kernelPackages.qc71_laptop];
  boot.kernelParams = [
    # "i915.enable_guc=2"
    # "i915.mitigations=off"
    "mitigations=off"
    "bgrt_disable"
    # "quiet"
  ];
  # boot.resumeDevice = "/dev/mapper/swap";
  boot.zfs.forceImportRoot = false; # Disable backwards compatibility options
  boot.zfs.unsafeAllowHibernation = true; # Make sure not use Swap on ZFS
  # Disable zfs-mount, use NixOS systemd mount management
  # Ref: https://wiki.nixos.org/wiki/ZFS#ZFS_conflicting_with_systemd
  systemd.services.zfs-mount.enable = false;

  # disko will take care of filesystems.*, swapDevices, boot.resumeDevice, boot.initrd.luks.devices

  networking.useDHCP = true;
  networking.hostId = "5736070c"; # ZFS requires this

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
}

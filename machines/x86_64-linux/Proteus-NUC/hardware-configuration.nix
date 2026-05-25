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
  boot.initrd.kernelModules = [ ];
  # boot.extraModulePackages = [config.boot.kernelPackages.qc71_laptop];
  boot.kernelModules = [ "kvm-intel" ];
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

  # Impermanence: Rollback `/` to blank snapshot on boot
  # `-r` destroys any snapshots and bookmarks more recent than the one
  # specified
  boot.initrd.systemd.services."zfs-rollback-root" = {
    description = "Rollback zroot/root@blank in initrd";
    wantedBy = [ "zfs-import.target" ];
    after = [ "zfs-import-zroot.service" ]; # Make sure zroot is imported
    before = [ "sysroot.mount" ]; # Make sure this happens before root is mounted
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.boot.zfs.package}/sbin/zfs rollback -r zroot/root@blank";
    };
  };
  # boot.initrd.systemd.services."zfs-rollback-home" = {
  #   description = "Rollback zroot/home@blank in initrd";
  #   wantedBy = ["zfs-import.target"];
  #   after = ["zfs-import-zroot.service"];
  #   before = ["sysroot.mount"];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${config.boot.zfs.package}/sbin/zfs rollback -r zroot/home@blank";
  #   };
  # };

  # disko will take care of filesystems.*, swapDevices, boot.resumeDevice, boot.initrd.luks.devices

  networking.useDHCP = true;
  networking.hostId = "5736070c"; # ZFS requires this

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
}

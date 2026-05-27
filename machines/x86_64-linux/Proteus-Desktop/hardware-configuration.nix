{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ehci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "uas"
    "sd_mod"
  ]
  ++ lib.optional config.boot.initrd.systemd.network.enable "r8169";
  boot.zfs.forceImportRoot = false; # Disable backwards compatibility options

  boot.initrd.systemd.enable = true; # Hibernation requirement
  boot.zfs.unsafeAllowHibernation = true; # Make sure not use Swap on ZFS

  # Disable zfs-mount, use NixOS systemd mount management
  # Ref: https://wiki.nixos.org/wiki/ZFS#ZFS_conflicting_with_systemd
  systemd.services.zfs-mount.enable = false;

  # disko will take care of filesystems.*, swapDevices, boot.resumeDevice, boot.initrd.luks.devices

  environment.etc.crypttab.text =
    let
      satas = [
        "ata-ST500DM002-1BD142_S2A7EA2P"
        "ata-WDC_WD5000AAKX-001CA0_WD-WMAYU5316042"
        "ata-WDC_WD5000AAKX-60U6AA0_WD-WCC2E3HEXA48"
        "ata-ST1000DM003-1CH162_S1DE5CWF"
        "ata-ST1000LM048-2E7172_WKPEZYSN"
        "ata-WDC_WD2002FYPS-02W3B0_WCAVY6186321"
      ];
      mnt_opts = "nofail,luks,discard,no-read-workqueue,no-write-workqueue";
      key_file = "/persistent/etc/dm_keyfile.key"; # TODO: Unsafe
    in
    lib.concatLines (map (disk_id: "crypted-${disk_id} /dev/disk/by-id/${disk_id}-part1 ${key_file} ${mnt_opts}") satas);

  networking.useDHCP = true;
  networking.hostId = "953b2f69"; # ZFS requires this

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
}

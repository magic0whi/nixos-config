{
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
  ];
  boot.kernelModules = [ "kvm-amd" ];
}

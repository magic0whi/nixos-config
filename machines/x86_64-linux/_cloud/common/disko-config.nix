{
  # disko will take care of filesystems.*, swapDevices, boot.resumeDevice, boot.initrd.luks.devices
  disko.devices.disk.main = {
    imageSize = "4G"; # Used for NixOS disk image generation, which can be used with `dd` on low RAM devices
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          label = "EFI SYSTEM PARTITION";
          type = "C12A7328-F81F-11D2-BA4B-00A0C93EC93B";
          size = "512M";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            extraArgs = [
              "-F32"
              "-S4096"
              "-nBOOT"
            ];
            mountOptions = [
              "umask=0077"
              "utf8" # supersedes iocharset
              # "iocharset=utf8" # Prevents character encoding issues
              # Keeps long filenames intact while preserving short-name compatibility for picky UEFI firmware or Windows dual-boot tools
              "shortname=mixed"
              # "errors=remount-ro"
              "discard"
            ];
          };
        };
      };
    };
  };
}

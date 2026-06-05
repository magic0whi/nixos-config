{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_proteus-nixos-5";
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
            mountpoint = "/boot";
            format = "vfat";
            extraArgs = [
              "-F32"
              "-S4096"
              "-nBOOT"
            ];
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@root" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd" ];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@persistent" = {
                mountpoint = "/persistent";
                mountOptions = [ "compress=zstd" ];
              };
              "@swap" = {
                mountpoint = "/.swapvol";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
                swap.swapfile.size = "2G";
              };
            };
          };
        };
      };
    };
  };
}

_: {
  disko.devices.disk.main = {
    imageSize = "4G"; # Used for NixOS disk image generation, which can be used with `dd` on low RAM devices
    type = "disk";
    device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_proteus-nixos-1";
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
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ]; # Override existing partition
            # Subvolumes must set a mountpoint in order to be mounted, unless their parent is mounted
            subvolumes = {
              "/rootfs" = {
                mountpoint = "/";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "nodatacow"
                  "discard=async"
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = [
                  "discard=async"
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@persistent" = {
                # TODO rename
                mountpoint = "/persistent";
                mountOptions = [
                  "discard=async"
                  "compress=zstd"
                  "noatime"
                ];
              };
              # Subvolume for the swapfile
              "@swap" = {
                # TODO rename
                mountpoint = "/.swapvol";
                mountOptions = [
                  "discard=async"
                  "noatime"
                ];
                swap = {
                  swapfile.size = "2G";
                  # swapfile2.size = "20M";
                  # swapfile2.path = "rel-path";
                };
              };
            };
            # mountpoint = "/btrfs-root";
            # swap = { # swapfiles under `/btrfs-root`
            #   swapfile.size = "20M";
            #   swapfile1.size = "20M";
            # };
          };
        };
      };
    };
  };
}

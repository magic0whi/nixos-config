{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/mmc-SD16G_0x000001d1";
        content = {
          type = "gpt";
          partitions = {
            spl = {
              priority = 1;
              type = "2E54B353-1271-4842-806F-E436D6AF6985";
              size = "2M";
            };
            uboot = {
              priority = 2;
              type = "BC13C2FF-59E6-4262-A352-B275FD6F7172";
              size = "4M";
            };
            boot = {
              priority = 3;
              size = "512M";
              type = "C12A7328-F81F-11D2-BA4B-00A0C93EC93B";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                extraArgs = [
                  "-F32"
                  "-S4096"
                  "-nBOOT"
                ];
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              # NOTE 100% partition has very low priority,
              # ref: https://github.com/nix-community/disko/blob/115e5211780054d8a890b41f0b7734cafad54dfe/lib/types/gpt.nix#L116
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                # mountpoint = "/btrfs-root";
                subvolumes = {
                  # I no longer prefer btrfs subvolume naming convention
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
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/persistent" = {
                    mountpoint = "/persistent";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "/swap" = {
                    mountpoint = "/.swapvol";
                    swap.hibernate-test.size = "8G";
                    mountOptions = [ "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}

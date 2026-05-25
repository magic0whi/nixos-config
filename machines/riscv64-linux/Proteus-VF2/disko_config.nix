_: {
  disko.devices = {
    # TF Card Root Drive (ZFS with Impermanence)
    disk.nvme0 = {
      device = "/dev/disk/by-id/TODO";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            label = "EFI SYSTEM PARTITION";
            # https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs
            type = "C12A7328-F81F-11D2-BA4B-00A0C93EC93B";
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              extraArgs = [
                "-F32"
                "-S4096"
                "-nBOOT"
              ];
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          plain_swap = {
            label = "SWAP PARTITION";
            type = "0657FD6D-A4AB-43C4-84E5-0933C84B4F4F";
            size = "8G";
            content = {
              type = "swap";
              discardPolicy = "both";
              resumeDevice = true;
            };
          };
          zfs_root = {
            label = "ZROOT PARTITION";
            type = "6A85CF4D-1DD2-11B2-99A6-080020736631";
            size = "100%";
            content = {
              type = "zfs";
              pool = "zroot";
            };
          };
        };
      };
    };
    # ZFS ROOT POOL (NVMe) - Impermanence Setup
    zpool.zroot = {
      type = "zpool";
      options.ashift = "12"; # Pool-level options
      # Dataset defaults
      rootFsOptions = {
        # ACL and Extended Attributes
        acltype = "posixacl";
        xattr = "sa";
        # Performance
        dnodesize = "auto";
        normalization = "formD";
        relatime = "on";

        compression = "zstd";

        devices = "off"; # Security
        # Mount behavior
        mountpoint = "/";
        canmount = "off";
      };
      mode = "";
      postCreateHook = "zpool set bootfs=zroot/root zroot;" + "zpool set cachefile=/etc/zfs/zpool.cache zroot"; # Create zpool.cache
      datasets = {
        # ROOT dataset (ephemeral, rolled back to blank on boot)
        root = {
          type = "zfs_fs";
          mountpoint = "/";
          options."com.sun:auto-snapshot" = "false";
          postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot/root@blank$' || zfs snapshot zroot/root@blank";
        };
        home = {
          type = "zfs_fs";
          mountpoint = "/home";
          # Used by `services.zfs.autoSnapshot.*` options.
          options."com.sun:auto-snapshot" = "true";
        };
        "home/root" = {
          type = "zfs_fs";
          mountpoint = "/root";
        };
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options."com.sun:auto-snapshot" = "false";
          options.atime = "off";
        };
        persistent = {
          type = "zfs_fs";
          mountpoint = "/persistent";
          options."com.sun:auto-snapshot" = "false";
        };
      };
    };
  };
}

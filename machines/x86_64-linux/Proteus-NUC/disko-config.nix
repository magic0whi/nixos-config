let
  # LUKS-encrypted ZFS disk helper (460GB partition)
  zroot = "zroot";
  mk_luks_part = disk_id: {
    type = "CA7D7CCB-63ED-4C53-861C-1742536059CC";
    size = "500106240K"; # Unit is KiB, ~512G
    content = {
      type = "luks";
      name = "crypted-${disk_id}";
      # passwordFile = "/tmp/dm_password.key";
      # For boot.initrd.luks.device.<name>.*
      settings = {
        # keyFile = "/etc/dm_keyfile.key";
        allowDiscards = true;
        bypassWorkqueues = true;
        # fallbackToPassword = false;
      };
      content = {
        type = "zfs";
        pool = zroot;
      };
    };
  };
in
{
  disko.devices = {
    # NVMe (953.9G) with ESP + swap + zroot1 + Windows 11
    disk = {
      nvme0 =
        let
          disk_id = "nvme-SAMSUNG_MZVL21T0HCLR-00B00_S676NX0T115316";
        in
        {
          device = "/dev/disk/by-id/${disk_id}";
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
              encrypted_swap = {
                label = "SWAP";
                type = "0657FD6D-A4AB-43C4-84E5-0933C84B4F4F";
                size = "32G";
                content = {
                  type = "swap";
                  discardPolicy = "both";
                  resumeDevice = true;
                  randomEncryption = true;
                  # Not supported by disko yet
                  # encrypted.enable = true;
                  # encrypted.label = "swap";
                  # encrypted.blkDev = "/dev/disk/by-id/nvme-eui.002538b121b3218a-part2";
                };
              };
              luks_part = mk_luks_part disk_id;
              # Optional spare/unused space for Microsoft(R) Windows
              windows = {
                label = "WINDOWS";
                type = "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"; # aka. Basic data partition
                size = "100%";
              };
            };
          };
        };
      # Smaller NVMe fully used for LUKS+ZFS
      nvme1 =
        let
          disk_id = "nvme-SAMSUNG_MZVLB512HAJQ-000L2_S3RGNF0K901813";
        in
        {
          device = "/dev/disk/by-id/${disk_id}";
          type = "disk";
          content = {
            type = "gpt";
            partitions.luks_part = mk_luks_part disk_id;
          };
        };
    };
    # ROOT POOL (NVMe) - Impermanence Setup
    zpool.zroot = {
      type = "zpool";
      mode = ""; # stripe (RAID-0)
      options.ashift = "12"; # Pool-level options
      # Dataset defaults
      rootFsOptions = {
        # ACL and Extended Attributes
        acltype = "posixacl";
        xattr = "sa";
        # Performance
        dnodesize = "auto";
        normalization = "formD";
        # relatime = "on"; # Updates atime only when the existing atime is older than the mtime
        atime = "off"; # Disable atime at all

        compression = "zstd";

        devices = "off"; # Security
        # Mount behavior
        mountpoint = "/";
        canmount = "off";
      };
      # Create zpool.cache
      postCreateHook = "zpool set bootfs=${zroot}/root ${zroot};" + "zpool set cachefile=/etc/zfs/zpool.cache ${zroot}";
      datasets = {
        # ROOT dataset (ephemeral, rolled back to blank on boot)
        root = {
          type = "zfs_fs";
          mountpoint = "/";
          # `com.sun:auto-snapshot` is used by options `services.zfs.autoSnapshot.*`
          options."com.sun:auto-snapshot" = "false";
          postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^${zroot}/root@blank$' || zfs snapshot ${zroot}/root@blank";
        };
        # TODO add rollback when I ready to move to impermanence on /home
        home = {
          type = "zfs_fs";
          mountpoint = "/home";
          options."com.sun:auto-snapshot" = "false";
        };
        "home/root" = {
          type = "zfs_fs";
          mountpoint = "/root";
        };
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options."com.sun:auto-snapshot" = "false";
        };
        persistent = {
          type = "zfs_fs";
          mountpoint = "/persistent";
          options."com.sun:auto-snapshot" = "true";
          mountOptions = [
            "defaults"
            "x-gvfs-trash"
          ];
        };
      };
    };
  };
}

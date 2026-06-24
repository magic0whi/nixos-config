# disko will take care of filesystems.*, swapDevices, boot.resumeDevice, boot.initrd.luks.devices
{ const, lib, ... }:
let
  luks_settings = name: {
    type = "CA7D7CCB-63ED-4C53-861C-1742536059CC";
    content = {
      type = "luks";
      name = "crypted-${name}";
      # passwordFile = "/tmp/dm_password.key";
      initrdUnlock = false; # Manually manage in stage 2 by `environment.etc."crypttab"`
      # For boot.initrd.luks.device.<name>.*
      settings = {
        crypttabExtraOpts = [ "nofail" ];
        # keyFile = "/etc/dm_keyfile.key"; # Conflicts with Clevis
        keyFileTimeout = 15;
        allowDiscards = true;
        bypassWorkqueues = true;
        # fallbackToPassword = false;
      };
      content = {
        type = "zfs";
        pool = "storage";
      };
    };
  };
  # LUKS-encrypted ZFS disk helper
  mk_luks_zfs_disk = disk_id: {
    device = "/dev/disk/by-id/${disk_id}";
    type = "disk";
    content = {
      type = "gpt";
      partitions.luks_part = (luks_settings disk_id) // {
        priority = 1; # ~465.8G
        size = "488385536K";
      };
    };
  };
in
{
  disko.devices = {
    # --- 1. NVMe Root Drive (ZFS with Impermanence) ---
    disk = {
      nvme0 = {
        device = "/dev/disk/by-id/nvme-HP_SSD_EX900_250GB_HBSE28061201109";
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
              size = "24G";
              content = {
                type = "swap";
                discardPolicy = "both";
                resumeDevice = true; # disko will set boot.resumeDevice
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
      # --- 2. SATA Data Drives (LUKS + ZFS RAIDZ2) ---
      # Better list them here one-by-one than iterate and append at the end of this attrset
      sata1 = mk_luks_zfs_disk "ata-ST500DM002-1BD142_S2A7EA2P";
      sata2 = mk_luks_zfs_disk "ata-WDC_WD5000AAKX-001CA0_WD-WMAYU5316042";
      sata3 = mk_luks_zfs_disk "ata-WDC_WD5000AAKX-60U6AA0_WD-WCC2E3HEXA48";
      sata4 = lib.mkMerge [
        (mk_luks_zfs_disk "ata-ST1000DM003-1CH162_S1DE5CWF")
        {
          content.partitions.storage2 = (luks_settings "storage2-ata-ST1000DM003-1CH162_S1DE5CWF") // {
            priority = 2;
            size = "488375296K"; # ~465.8GB
          };
        }
      ];
      sata5 = mk_luks_zfs_disk "ata-ST1000LM048-2E7172_WKPEZYSN";
      sata6 = lib.mkMerge [
        (mk_luks_zfs_disk "ata-WDC_WD2002FYPS-02W3B0_WCAVY6186321")
        {
          content.partitions.storage2 = (luks_settings "storage2-ata-WDC_WD2002FYPS-02W3B0_WCAVY6186321") // {
            priority = 2;
            size = "488375296K"; # ~465.8GB
          };
        }
      ];
    };
    # --- 3. ZFS Pools ---
    zpool =
      let
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
          mountpoint = "none";
          canmount = "off";
        };
      in
      {
        # NVMe (Impermanence Setup)
        zroot = {
          inherit type options;
          # mode = ""; # default "" means stripe (RAID-0)
          rootFsOptions = rootFsOptions // {
            mountpoint = "/";
          };
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
              # `com.sun:auto-snapshot` is used by options `services.zfs.autoSnapshot.*`
              type = "zfs_fs";
              mountpoint = "/home";
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
        # 6 SATAs RAIDZ2 (RAID-6)
        storage = {
          inherit type options rootFsOptions;
          mode = "raidz2";
          datasets.data = {
            type = "zfs_fs";
            mountpoint = const.storagePath;
            mountOptions = [ "nofail" ];
            options.canmount = "on";
          };
        };
        # 2 SATAs RAID-0
        storage2 = {
          inherit type options rootFsOptions;
          datasets.data = {
            type = "zfs_fs";
            # Matches the mountpoint shown in your zfs list output
            mountpoint = "/mnt/storage/data2";
            mountOptions = [ "nofail" ];
            options.canmount = "on";
          };
        };
      };
  };
  environment.etc.crypttab.text =
    let
      storage = [
        "ata-ST500DM002-1BD142_S2A7EA2P"
        "ata-WDC_WD5000AAKX-001CA0_WD-WMAYU5316042"
        "ata-WDC_WD5000AAKX-60U6AA0_WD-WCC2E3HEXA48"
        "ata-ST1000DM003-1CH162_S1DE5CWF"
        "ata-ST1000LM048-2E7172_WKPEZYSN"
        "ata-WDC_WD2002FYPS-02W3B0_WCAVY6186321"
      ];
      storage2 = [
        "ata-ST1000LM048-2E7172_WKPEZYSN"
        "ata-WDC_WD2002FYPS-02W3B0_WCAVY6186321"
      ];
      mnt_opts = "nofail,luks,discard,no-read-workqueue,no-write-workqueue";
      key_file = "/persistent/etc/dm_keyfile.key"; # TODO: Unsafe
    in
    lib.concatLines (map (disk_id: "crypted-${disk_id} /dev/disk/by-id/${disk_id}-part1 ${key_file} ${mnt_opts}") storage)
    + lib.concatLines (
      map (disk_id: "crypted-storage2-${disk_id} /dev/disk/by-id/${disk_id}-part2 ${key_file} ${mnt_opts}") storage2
    );
}

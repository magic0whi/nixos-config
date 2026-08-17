{
  config,
  const,
  lib,
  ...
}:
{
  # DEBUG
  boot.initrd.systemd.emergencyAccess = const.initial_hashed_password;

  # boot.initrd.systemd.extraBin.btrfs = "${pkgs.btrfs-progs}/bin/btrfs"; # Ensure btrfs tool is available in initrd
  # https://github.com/LFour86/nixos-lf/blob/f3f6e5d09f4a04b696e906313f338ee8736cccac/system/programs/systemd.nix
  boot.initrd.systemd.services.rollback = {
    description = "Rollback BTRFS root subvolume to a pristine state";
    wantedBy = [ "initrd.target" ];
    after = [ "initrd-root-device.target" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script =
      let
        subvolumes = config.disko.devices.disk.main.content.partitions.root.content.content.subvolumes;

        root_subvol = lib.pipe subvolumes [
          (lib.filterAttrs (_: sv: sv.mountpoint == "/"))
          builtins.attrNames
          builtins.head
        ];

        # Every other subvolume (/nix, /home, /persistent, ...) is mounted under
        # the pristine root, so its mount point must already exist inside the
        # freshly-created (empty) root subvolume.
        bootMountDirs = lib.pipe subvolumes [
          builtins.attrValues
          (map (sv: sv.mountpoint))
          (builtins.filter (mp: mp != null && mp != "/"))
          (map (mp: "/btrfs_tmp/${root_subvol}${mp}"))
          (builtins.concatStringsSep " ")
        ];
      in
      ''
        set -euo pipefail

        mkdir /btrfs_tmp
        mount ${config.fileSystems."/".device} /btrfs_tmp

        # Ensure /sysroot is not mounted before we delete the subvolume
        if mountpoint -q /sysroot 2>/dev/null; then
          echo "Warning: /sysroot is already mounted, unmounting it to avoid conflicts..."
          umount /sysroot || true
        fi

        if [[ -d /btrfs_tmp/${root_subvol} ]]; then
          echo "Removing existing root subvolume and all descendants recursively..."
          btrfs subvolume delete -R /btrfs_tmp/${root_subvol}
        fi

        echo "Creating new pristine root subvolume..."
        btrfs subvolume create /btrfs_tmp/${root_subvol}

        echo "Recreating mount points inside the pristine root..."
        mkdir -p ${bootMountDirs}

        umount /btrfs_tmp
        rmdir /btrfs_tmp
      '';
  };
}

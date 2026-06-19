{ config, const, ... }:
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
    script = ''
      export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
      set -euo pipefail

      mkdir /btrfs_tmp
      mount ${config.fileSystems."/".device} /btrfs_tmp

      # Ensure /sysroot is not mounted before we delete the subvolume
      if mountpoint -q /sysroot 2>/dev/null; then
        echo "Warning: /sysroot is already mounted, unmounting it to avoid conflicts..."
        umount /sysroot || true
      fi

      if [[ -d /btrfs_tmp/rootfs ]]; then
        echo "Removing existing root subvolume and all descendants recursively..."
        btrfs subvolume delete -R /btrfs_tmp/rootfs
      fi

      echo "Creating new pristine root subvolume..."
      btrfs subvolume create /btrfs_tmp/rootfs

      umount /btrfs_tmp
      rmdir /btrfs_tmp
    '';
  };
}

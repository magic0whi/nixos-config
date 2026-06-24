{ config, ... }:
{
  # Note this might jump back and forth as kernels are added or removed.
  boot.requiredKernelModules = [ config.boot.zfs.package.kernelModuleAttribute ];
  # Example of pinning the kernel package
  # boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linuxKernel.kernels.linux_6_19.override {
  #   argsOverride = let version = "6.19.3"; in {
  #     inherit version;
  #     modDirVersion = lib.versions.pad 3 version;
  #     src = pkgs.fetchurl {
  #       url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${version}.tar.xz";
  #       hash = "sha256-DkdJaK38vuMpFv0BqJ2Mz9EWjY0yVp52pcZkx5MZjr4=";
  #     };
  #   };
  # });
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  boot.zfs.forceImportRoot = false; # Disable backwards compatibility options
  boot.zfs.unsafeAllowHibernation = true; # Make sure not having Swap on ZFS
  # Disable zfs-mount, use NixOS systemd mount management
  # Ref: https://wiki.nixos.org/wiki/ZFS#ZFS_conflicting_with_systemd
  systemd.services.zfs-mount.enable = false;
}

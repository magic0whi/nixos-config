{
  config,
  lib,
  pkgs,
  ...
}:
let
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
    && (!kernelPackages.rtl8812au.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (builtins.attrValues zfsCompatibleKernelPackages)
  );
in
{
  # Note this might jump back and forth as kernels are added or removed.
  boot.kernelPackages = latestKernelPackage;
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
}

{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.boot.requiredKernelModules = lib.mkOption {
    type = with lib.types; listOf str;
    default = [ ];
    description = "List of out-of-tree kernel package attributes that must not be broken.";
  };

  config.boot.kernelPackages =
    let
      compat_kernel_pkgs = lib.filterAttrs (
        pname: kernel_pkgs:
        (builtins.match "linux_[0-9]+_[0-9]+" pname) != null
        && (builtins.tryEval kernel_pkgs).success
        && (lib.all (mod_name: !kernel_pkgs.${mod_name}.meta.broken) config.boot.requiredKernelModules)
      ) pkgs.linuxKernel.packages;
    in
    lib.last (
      lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (builtins.attrValues compat_kernel_pkgs)
    );
}

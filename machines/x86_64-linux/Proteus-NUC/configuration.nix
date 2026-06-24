{ pkgs, ... }:
{
  services.sing-box.generateMobileConfig.enable = true;
  environment.systemPackages = with pkgs; [ bpftrace ]; # powerful tracing tool, ref: https://github.com/bpftrace/bpftrace
  ## BEGIN zfs.nix
  networking.hostId = "5736070c"; # ZFS requires this
  ## END zfs.nix
  ## BEGIN hardware.nix
  # boot.extraModulePackages = [config.boot.kernelPackages.qc71_laptop];
  boot.kernelParams = [
    # "i915.enable_guc=2"
    # "i915.mitigations=off"
    "mitigations=off"
    "bgrt_disable"
    # "quiet"
  ];

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-compute-runtime-legacy1
  ];
  ## END hardware.nix
  ## START thunderbolt.nix
  services.hardware.bolt.enable = true;
  ## END thunderbolt.nix
}

{ pkgs, ... }:
{
  services.sing-box.generateMobileConfig.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-compute-runtime-legacy1
  ];
  environment.systemPackages = with pkgs; [ bpftrace ]; # powerful tracing tool, ref: https://github.com/bpftrace/bpftrace
  ## START thunderbolt.nix
  services.hardware.bolt.enable = true;
  ## END thunderbolt.nix
}

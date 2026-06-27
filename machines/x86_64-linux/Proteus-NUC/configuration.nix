{ config, pkgs, ... }:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subs = [
        "sb-nuc"
        "syncthing-nuc"
        # "sftpgo"
      ];
      regHost = true;
    in
    {
      tailscale = {
        inherit regHost;
        ipv4 = "100.64.161.20/10";
        ipv6 = "fd7a:115c:a1e0::cd3a:a114/48";
        subdomains = {
          A = subs;
          AAAA = subs;
        };
      };
      easytier = {
        inherit regHost;
        ipv4 = "10.0.0.2/24";
        ipv6 = "fdfe:dcba:9877::2/64";
        subdomains = {
          A = subs;
          AAAA = subs;
        };
      };
      wire.name = "enp46s0";
    };
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

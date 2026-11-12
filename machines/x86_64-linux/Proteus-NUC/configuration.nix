{
  config,
  const,
  lib,
  pkgs,
  ...
}:
{
  vars.hostAddrs.${config.networking.hostName} = {
    easytier = {
      regHost = true;
      ipv4 = "10.0.0.2/24";
      ipv6 = "fdfe:dcba:9877::2/64";
    };
    # NOTE: Through we can use `enp46s0 = {}`, but I configured networkd-dispatcher which utilize the *.wire attribute
    wire.name = "enp46s0";
  };
  services.sing-box.generateMobileConfig.enable = true;
  # Since NUC is now under a sing-box gateway, don't autostart
  systemd.services.sing-box.wantedBy = lib.mkForce [ ];

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
  ## BEGIN easytier.nix
  services.easytier.instances.main.settings.peers = with const.networking.allHostAddrs; [
    "udp://${Proteus-Desktop.wire.ipv4NoCidr}"
  ];
  ## END easytier.nix
  boot.kernelPackages = pkgs.linuxPackagesFor (
    pkgs.linuxKernel.kernels.linux_7_3.override {
      argsOverride =
        let
          # Pin 7.2.15: external monitor stays black after DPMS off on 6.18, and ZFS 2.4.4 is marked broken on 7.3.
          version = "7.2.15";
        in
        {
          inherit version;
          modDirVersion = lib.versions.pad 3 version;
          src = pkgs.fetchurl {
            url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${version}.tar.xz";
            sha256 = "1aq931l3mn0a3yix7qmkxnr1vxzw9c4afk2wxg57r4sc6bbv3xnh"; # from nixpkgs ed2b227^
          };
        };
    }
  );
}

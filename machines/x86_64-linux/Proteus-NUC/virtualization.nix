{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
let
  libvirt_cidr = "192.168.122.0/24";
in
{
  # virtualisation.waydroid.enable = true; # Usage: https://wiki.nixos.org/wiki/Waydroid
  ## BEGIN binfmt.nix
  boot.binfmt.emulatedSystems = [
    "riscv64-linux"
    "aarch64-linux"
  ]; # Cross compilation
  # For riscv64 docker container
  boot.binfmt.registrations."riscv64-linux" = {
    interpreter = "${lib.getExe' pkgs.pkgsStatic.qemu-user "qemu-riscv64"}";
    fixBinary = true;
    wrapInterpreterInShell = false;
  };
  ## END binfmt.nix
  ## BEGIN sriov.nix
  boot.extraModulePackages = with pkgs; [
    i915-sriov
    xe-sriov
  ];
  boot.kernelParams = [
    "intel_iommu=on"
    # Gen11
    "i915.enable_guc=3"
    "i915.max_vfs=7"
    "module_blacklist=xe"
    # Gen12 and later
    # "xe.max_vfs=7"
    # "xe.force_probe=0x9a60" # cat /sys/devices/pci0000:00/0000:00:02.0/device
    # "module_blacklist=i915"
  ];
  ## END sriov.nix
  ## BEGIN libvirtd.nix
  users.users.${myvars.username}.extraGroups = [ "libvirtd" ];
  networking = {
    nftables.tables = lib.mkIf config.services.sing-box.enable {
      sb_libvirt_fix = {
        family = "inet";
        content = ''
          chain libvirt-prerouting {
            type filter hook prerouting priority dstnat - 5; policy accept;

            # Do NOT bypass FakeIP traffic. Let sing-box handle it.
            ip daddr 198.18.0.0/15 return

            # Bypass everything else from Libvirt
            ip saddr ${libvirt_cidr} ct mark set 0x00002024
          }
        '';
      };
    };
    firewall.extraInputRules = lib.mkIf config.services.sing-box.enable ''
      ip saddr ${libvirt_cidr} accept comment "Allow Libvirt to reach auto_redirect ports"
    '';
  };
  systemd.network = lib.mkIf (!config.services.sing-box.enable) {
    netdevs."20-macvtap0" = {
      netdevConfig = {
        Kind = "macvtap";
        Name = "macvtap0";
      };
      macvtapConfig.Mode = "vepa";
    };
    networks = {
      "10-enp46s0" = {
        matchConfig.Name = "enp46s0";
        linkConfig.RequiredForOnline = "carrier"; # for `systemd-networkd-wait-online.service`. carroer = cable plugged
        macvtap = [ "macvtap0" ];
        DHCP = "no";
        networkConfig = {
          IPv6AcceptRA = false;
          LinkLocalAddressing = false;
          MulticastDNS = false; # mDNS resolve local hostname (e.g., `.local`), without needing a DNS
          LLMNR = false; # hardening, Link-Local Multicast Name Resolution is a fallback when DNS cannot be reached
        };
        # The `Metric` option is for static routes while the `RouteMetric` option is for setups not using static routes.
        dhcpV4Config.RouteMetric = 10;
        ipv6AcceptRAConfig.RouteMetric = 10;
      };
      "20-macvtap0" = {
        matchConfig.Name = "macvtap0";
        DHCP = "yes";
        dhcpV4Config.RouteMetric = 10;
        ipv6AcceptRAConfig.RouteMetric = 10;
      };
    };
  };
  # Enable nested virtualization, required by security containers and nested vm.
  # This should be set per host in /hosts, not here.
  # - For AMD CPU, add "kvm-amd" to kernelModules.
  #   boot.kernelModules = ["kvm-amd"];
  #   boot.extraModprobeConfig = "options kvm_amd nested=1"; # for amd cpu
  # - For Intel CPU, add "kvm-intel" to kernelModules.
  #   boot.kernelModules = ["kvm-intel"];
  #   boot.extraModprobeConfig = "options kvm_intel nested=1"; # for intel cpu
  boot.kernelModules = [
    "kvm-intel"
    "vfio-pci"
  ];
  # To dry-run, run `sudo udevadm test -a add /sys/bus/pci/devices/0000:00:02.1`
  services.udev.extraRules = ''
    # Bind all i915 VFs (00:02.1 to 00:02.7) to vfio-pci
    ${builtins.concatStringsSep ", " [
      ''ACTION=="add", SUBSYSTEM=="pci"''
      ''KERNEL=="${builtins.head (lib.splitString "." myvars.igpu_pci_ids)}.[1-7]"''
      ''ATTR{vendor}=="0x8086", ATTR{device}=="0x9a60"''
      ''DRIVER!="vfio-pci"''
      ''RUN+="${pkgs.writeShellScript "i915-bind-to-vfio-pci" ''
        echo $1 > /sys/bus/pci/devices/$1/driver/unbind
        echo vfio-pci > /sys/bus/pci/devices/$1/driver_override
        ${lib.getExe' pkgs.kmod "modprobe"} vfio-pci
        echo $1 > /sys/bus/pci/drivers/vfio-pci/bind
      ''} $kernel"''
    ]}
  '';
  virtualisation = {
    spiceUSBRedirection.enable = true;
    # lxd.enable = true;
    libvirtd =
      let
        domain_name = "win11";
      in
      {
        enable = true;
        qemu.swtpm.enable = true;
        qemu.vhostUserPackages = [ pkgs.virtiofsd ];
        # hooks.qemu."99-hugepages.sh" = pkgs.writeShellScript "99-hugepages.sh" ''
        #   set -eufo pipefail
        #   # ## BEGIN DEBUG
        #   # LOG=/var/log/libvirt/hooks-qemu.log
        #   # exec >>"$LOG" 2>&1
        #   # set -x
        #   # echo "---- $(date -Is) ----"
        #   # echo "argv: $0 $*"
        #   # env | sort
        #   # ## END DEBUG

        #   DOMAIN_XML="$(cat)"
        #   VM="$1"
        #   OP="$2"
        #   SUBOP="$3"

        #   [ "$VM" = "${domain_name}" ] || exit 0 # Only for this VM

        #   MEM_MIB=$((
        #     $(printf '%s' "$DOMAIN_XML" \
        #     | ${lib.getExe' pkgs.libxml2 "xmllint"} --xpath "string(//domain/memory)" -) / 1024
        #   )) # Unit in xml is KiB
        #   HP_SIZE_KB=$(${lib.getExe pkgs.gawk} '/Hugepagesize:/ { print $2 }' /proc/meminfo)
        #   HP_SYSFS="/sys/kernel/mm/hugepages/hugepages-''${HP_SIZE_KB}kB/nr_hugepages"

        #   STATE_DIR="/run/libvirt-hugepages"
        #   STATE_FILE="$STATE_DIR/$VM.baseline"

        #   pages_needed() {
        #     echo $(((MEM_MIB * 1024) / HP_SIZE_KB))
        #   }

        #   get_current() {
        #     cat "$HP_SYSFS"
        #   }

        #   set_target() {
        #     local target="$1"
        #     echo "$target" > "$HP_SYSFS"
        #   }

        #   alloc_if_needed() {
        #     mkdir -p "$STATE_DIR"

        #     local baseline current need target
        #     current="$(get_current)"
        #     baseline="$current"
        #     echo "$baseline" > "$STATE_FILE"

        #     need="$(pages_needed)"
        #     target=$((baseline + need))

        #     # Only grow pool if we don't already have enough
        #     if [ "$current" -lt "$target" ]; then
        #       set_target "$target"
        #     fi
        #   }

        #   restore_baseline() {
        #     [ -f "$STATE_FILE" ] || exit 0
        #     local baseline
        #     baseline="$(cat "$STATE_FILE")"

        #     # Restore exactly to what it was before starting this VM
        #     set_target "$baseline"
        #     rm -f "$STATE_FILE"
        #   }

        #   case "$OP $SUBOP" in
        #     "prepare begin")
        #       alloc_if_needed
        #       ;;
        #     "release end")
        #       restore_baseline
        #       ;;
        #   esac
        # '';
        hooks.qemu."10-igpu-sriov.sh" = pkgs.writeShellScript "10-igpu-sriov.sh" ''
          set -eufo pipefail

          VM="$1"
          OP="$2"
          SUBOP="$3"

          [ "$VM" = "${domain_name}" ] || exit 0 # Apply to this specific VM

          SRIOV_PATH="/sys/bus/pci/devices/${myvars.igpu_pci_ids}/sriov_numvfs"

          # Check if the sysfs path exists before trying to read/write
          if [ ! -f "$SRIOV_PATH" ]; then
            echo "SR-IOV path $SRIOV_PATH not found" >&2
            exit 0
          fi

          CURRENT_VFS=$(cat "$SRIOV_PATH")

          case "$OP $SUBOP" in
            "prepare begin")
              NEW_VFS=$((CURRENT_VFS + 1))
              # Note: Depending on your iGPU driver, the Linux kernel might throw
              # "Device or resource busy" if you try to change sriov_numvfs
              # without setting it to 0 first. If your driver supports dynamic
              # scaling, this works natively.
              echo "$NEW_VFS" > "$SRIOV_PATH"
              ;;
            "release end")
              NEW_VFS=$((CURRENT_VFS - 1))
              # Safeguard to prevent negative values
              if [ "$NEW_VFS" -lt 0 ]; then
                NEW_VFS=0
              fi
              echo "$NEW_VFS" > "$SRIOV_PATH"
              ;;
          esac
        '';
      };
  };
  environment.systemPackages = with pkgs; [
    # This script is used to install the arm translation layer for waydroid
    # so that we can install arm apks on x86_64 waydroid
    # https://github.com/casualsnek/waydroid_script
    # https://github.com/AtaraxiaSjel/nur/tree/master/pkgs/waydroid-script
    # https://wiki.archlinux.org/title/Waydroid#ARM_Apps_Incompatible
    # nur-ataraxiasjel.packages.${pkgs.system}.waydroid-script

    # Need to add [File (in the menu bar) -> Add connection] when start for the first time
    virt-manager

    # QEMU/KVM (HostCpuOnly), provides:
    # - qemu-storage-daemon qemu-edid qemu-ga
    #   qemu-pr-helper qemu-nbd elf2dmp qemu-img qemu-io
    #   qemu-kvm qemu-system-x86_64 qemu-system-aarch64 qemu-system-i386
    # qemu_kvm

    # QEMU (other architectures), provides:
    #   qemu-loongarch64 qemu-system-loongarch64
    #   qemu-riscv64 qemu-system-riscv64 qemu-riscv32 qemu-system-riscv32
    #   qemu-system-arm qemu-arm qemu-armeb qemu-system-aarch64 qemu-aarch64 qemu-aarch64_be
    #   qemu-system-xtensa qemu-xtensa qemu-system-xtensaeb qemu-xtensaeb
    #   ......
    # qemu
  ];
  ## END libvirtd.nix
}

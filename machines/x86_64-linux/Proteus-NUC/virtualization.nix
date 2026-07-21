{
  config,
  lib,
  const,
  pkgs,
  NixVirt,
  ...
}:
let
  net_cidr = "192.168.122.0/24";

  # Libvirt network with PXE netbootxyz
  net_cfg =
    let
      prefix = lib.pipe net_cidr [
        (lib.splitString ".")
        (lib.take 3)
        (builtins.concatStringsSep ".")
      ];
    in
    {
      name = "default";
      uuid = "37176a39-9e69-4b64-a3b8-a83dc51f2f2c";
      forward.mode = "nat";
      bridge = {
        name = "virbr0";
        stp = true;
        delay = 0;
      };
      ip = {
        address = "${prefix}.1";
        netmask = "255.255.255.0";
        tftp.root = "/var/lib/libvirt/tftpboot";
        dhcp.range = {
          start = "${prefix}.2";
          end = "${prefix}.254";
        };
      };
      # Ref: https://wiki.archlinux.org/title/Dnsmasq#PXE_server
      "dnsmasq:options"."dnsmasq:option" = [
        { value = "dhcp-match=set:efi-x86_64,option:client-arch,7"; }
        { value = "dhcp-match=set:efi-x86_64,option:client-arch,9"; }
        { value = "dhcp-match=set:efi-aarch64,option:client-arch,11"; }

        { value = "dhcp-boot=tag:efi-x86_64,netbootxyz-x86_64.efi"; }
        { value = "dhcp-boot=tag:efi-aarch64,netbootxyz-aarch64.efi"; }
      ];
    };
in
{
  # virtualisation.waydroid.enable = true; # Usage: https://wiki.nixos.org/wiki/Waydroid
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
  users.users.${const.username}.extraGroups = [ "libvirtd" ];
  networking.firewall.extraInputRules = lib.mkIf config.services.sing-box.enable ''
    ip saddr ${net_cidr} accept comment "Allow Libvirt to reach auto_redirect ports"
  '';
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
      ''KERNEL=="${builtins.head (lib.splitString "." const.igpu_pci_ids)}.[1-7]"''
      ''ATTR{vendor}=="0x8086", ATTR{device}=="0x9a60"''
      ''DRIVER!="vfio-pci"''
      ''RUN+="${pkgs.writeShellScript "i915-bind-to-vfio-pci" ''
        set -euo pipefail
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
      # let
      #   domain_name = "win11";
      # in
      {
        enable = true;
        # qemu.swtpm.enable = true; # Already set by `virtualisation.libvirt.swtpm.enable`
        qemu.vhostUserPackages = [ pkgs.virtiofsd ];
        # hooks.qemu."99-hugepages.sh" = pkgs.writeShellScript "99-hugepages.sh" ''
        #   set -euo pipefail
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
      };
    ## NixVirt
    libvirt = {
      enable = true;
      swtpm.enable = true;
      connections."qemu:///system" = {
        networks = lib.singleton {
          active = true;
          # https://github.com/AshleyYakeley/NixVirt/blob/6d213ab42f72ba41c2eb4e6bdb97581c0642d942/generate-xml/network.nix
          definition =
            let
              inherit (NixVirt.lib.network) writeXML;
              # inherit (NixVirt.lib.network.templates) bridge;
            in
            writeXML net_cfg;
        };
        # https://github.com/AshleyYakeley/NixVirt/blob/6d213ab42f72ba41c2eb4e6bdb97581c0642d942/generate-xml/pool.nix
        pools =
          let
            inherit (NixVirt.lib.pool) writeXML;
            # inherit (NixVirt.lib.network.templates) bridge;
          in
          [
            {
              active = true;
              definition = writeXML {
                name = "default";
                type = "dir";
                uuid = "4a36aa09-a6eb-44e2-8a3d-d68d571122dc";
                target = {
                  path = "/var/lib/libvirt/images";
                  permissions = {
                    mode.octal = "0711";
                    owner.uid = 0;
                    group.gid = 0;
                  };
                };
              };
            }
            {
              active = true;
              definition = writeXML {
                name = "nvram";
                type = "dir";
                uuid = "c84a1df4-596b-442c-9810-f2ca876ced52";
                target = {
                  path = "/var/lib/libvirt/qemu/nvram";
                  permissions = {
                    mode.octal = "0755";
                    owner.uid = 0;
                    group.gid = 0;
                  };
                };
              };
            }
            {
              active = true;
              definition = writeXML {
                name = "zfs_images";
                type = "zfs";
                uuid = "f1e2db83-d5d0-462d-88f5-6c24a011598e";
                source.name = "zroot/vm-images";
                target.path = "/var/lib/libvirt/qemu/nvram";
              };
            }
          ];
      };
    };
  };

  systemd.tmpfiles.settings =
    let
      netbootxyz-x86_64 = (import pkgs.path { system = "x86_64-linux"; }).netbootxyz-efi;
      netbootxyz-aarch64 = (import pkgs.path { system = "aarch64-linux"; }).netbootxyz-efi;
      prefix = net_cfg.ip.tftp.root;
    in
    {
      # Intel GPU cannot setup SR-IOV when in use
      "01-igpu-sriov"."/sys/bus/pci/devices/${const.igpu_pci_ids}/sriov_numvfs".w.argument = "7";
      "01-tftpboot".${prefix}.d.mode = "0755";
      "02-tftpboot-netbootxyz-x86_64"."${prefix}/netbootxyz-x86_64.efi"."L+".argument = toString netbootxyz-x86_64;
      "02-tftpboot-netbootxyz-aarch64"."${prefix}/netbootxyz-aarch64.efi"."L+".argument = toString netbootxyz-aarch64;
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

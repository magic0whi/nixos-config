{ lib, pkgs, ... }:
{
  # List packages installed in system profile. To search, run: `nix search nixpkgs "^firefox"`
  environment.systemPackages =
    (with pkgs; [
      # System Monitoring
      # strace # system call monitoring
      # sysstat
      # iotop
      # nmon
      # nethogs # net top, grouping bandwidth by process
      # powertop

      # System Tools
      psmisc # killall/pstree/prtstat/fuser/...
      lm_sensors # for `sensors`
      # ethtool
      # hdparm # For disk performance
      # A tool that reads information about your system's hardware from the BIOS according to the SMBIOS/DMI standard
      # dmidecode
      # parted
      # nvme-cli
      cryptsetup # dm-crypt tools
      # nfs-utils # Linux user-space NFS utilities
    ])
    ++ lib.optional (!pkgs.stdenv.hostPlatform.isRiscV64) pkgs.ltrace; # library call monitoring
  # BCC - Tools for BPF-based Linux IO analysis, networking, monitoring, and more. Ref: https://github.com/iovisor/bcc
  # programs.bcc.enable = true;
}

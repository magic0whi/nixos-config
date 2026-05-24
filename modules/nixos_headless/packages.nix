{pkgs, ...}: {
  # List packages installed in system profile. To search, run: `nix search nixpkgs "^firefox"`
  environment.systemPackages = with pkgs;
    [
      # System Monitoring
      # strace # system call monitoring
      # sysstat
      # iotop
      # nmon

      # System Tools
      psmisc # killall/pstree/prtstat/fuser/...
      lm_sensors # for `sensors`
      # ethtool
      # hdparm # For disk performance
      # A tool that reads information about your system's hardware from the BIOS according to the SMBIOS/DMI standard
      # dmidecode
      # parted
      cryptsetup # dm-crypt tools
      # nfs-utils # Linux user-space NFS utilities
    ]
    ++ lib.optionals (!stdenv.hostPlatform.isRiscV64) [
      ltrace # library call monitoring
    ];
  # BCC - Tools for BPF-based Linux IO analysis, networking, monitoring, and more. Ref: https://github.com/iovisor/bcc
  # programs.bcc.enable = true;
}

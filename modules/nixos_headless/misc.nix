{
  config,
  lib,
  pkgs,
  ...
}:
{
  ## BEGIN bootloader.nix
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true; # Allow installation process to modify EFI boot variables
  boot.loader.systemd-boot = {
    enable = lib.mkDefault true;
    configurationLimit = 8; # Limit the boot loader entries
    consoleMode = "max";
  };
  boot.initrd.systemd.enable = true;
  ## END bootloader.nix

  ## BEGIN i18n.nix
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # i18n.extraLocaleSettings = {
  #   LC_ADDRESS = "en_US.UTF-8";
  #   LC_IDENTIFICATION = "en_US.UTF-8";
  #   LC_MEASUREMENT = "en_US.UTF-8";
  #   LC_MONETARY = "en_US.UTF-8";
  #   LC_NAME = "en_US.UTF-8";
  #   LC_NUMERIC = "en_US.UTF-8";
  #   LC_PAPER = "en_US.UTF-8";
  #   LC_TELEPHONE = "en_US.UTF-8";
  #   LC_TIME = "en_US.UTF-8";
  # };
  ## END i18n.nix

  ## BEGIN dbus.nix
  services.dbus.implementation = "broker";
  ## END dbus.nix

  ## BEGIN sysctl.nix
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "cake";
    "net.ipv4.tcp_fastopen" = 3; # Enable TFO on both outgoing and incoming
    "net.ipv4.tcp_mtu_probing" = 1; # Do MTU discovery when ICMP black hole detected
  };
  ## END sysctl.nix

  ## BEGIN network.nix
  networking = {
    useNetworkd = true;
    nftables.enable = true;
    # Or `services.timesyncd.servers`
    timeServers = [
      "ntp.aliyun.com" # Aliyun NTP Server
      "ntp.tencent.com" # Tencent NTP Server
    ];
  };

  services.vnstat.enable = true;
  ## END network.nix
  ## BEGIN journald.nix
  services.journald = {
    rateLimitInterval = "1min"; # The time window (1 minute) used to calculate the message limit.
    # The maximum number of log lines a single service can generate within the time window before being throttled.
    rateLimitBurst = 500;
    extraConfig = ''
      # Keep logs for 1 month max
      MaxRetentionSec=1month
      # Limit total disk usage to 1GB
      SystemMaxUse=1G
      # Limit individual file size to 64MB to ensure clean rotation
      SystemMaxFileSize=128M
      # Ensure at least 15% of disk stays free
      SystemKeepFree=15%
      # Prevent logs from eating up /run (RAM) during bursts
      RuntimeMaxUse=64M
    '';
  };
  ## END journald.nix
  ## BEGIN tweaks.nix
  # TIP: `swapon -s` to list swaps and their priority
  zramSwap.enable = true;
  systemd.oomd.settings.OOM = {
    DefaultMemoryPressureLimit = "75%";
    DefaultMemoryPressureDurationSec = "10s";
  };
  ## END tweaks.nix
  ## BEGIN security.nix
  # Without polkit, sing-box can't interact with systemd-resolved
  security = {
    polkit.enable = true;
    pam = {
      rssh.enable = true; # PAM auth via forwarded SSH agent, implicitly add `Default env_keep+=SSH_AUTH_SOCK`
      services.sudo.rssh = true; # passwordless sudo on remote
    };
    sudo = {
      package = if config.services.sssd.enable then pkgs.sudo.override { withSssd = true; } else pkgs.sudo;
      extraConfig = ''
        # Disable timeout for sudo prompt
        Defaults passwd_timeout=0
      '';
    };
  };
  security.sudo-rs = {
    enable = true;
    inherit (config.security.sudo) extraConfig;
  };
  ## END security.nix
}

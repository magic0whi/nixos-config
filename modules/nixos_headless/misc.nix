{
  config,
  lib,
  myvars,
  pkgs,
  ...
}: {
  ## BEGIN bootloader.nix
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true; # Allow installation process to modify EFI boot variables
  boot.loader.systemd-boot = {
    enable = lib.mkDefault true;
    configurationLimit = 4; # Limit the boot loader entries
    consoleMode = "max";
  };
  ## END bootloader.nix
  ## BEGIN nix.nix
  nix = {
    gc.dates = "weekly";
    settings.auto-optimise-store = true; # Optimise the store after each build
  };
  ## END nix.nix
  ## BEGIN ssh.nix
  services.openssh.settings.PasswordAuthentication = false; # Disable password login
  programs.ssh.extraConfig = ''
    Host *
      IdentityAgent /run/user/${toString config.users.users.${myvars.username}.uid}/gnupg/S.gpg-agent.ssh
  '';
  # The OpenSSH agent remembers private keys for you. So that you don’t have to type in passphrases every time you make
  # an SSH connection.
  # TIP: Use `ssh-add` to add a key to the agent.
  # NOTE: You cannot use ssh-agent and GnuPG agent with SSH support at the same time
  # ssh.startAgent = true;
  ## END ssh.nix

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
  boot.kernel.sysctl."net.ipv4.tcp_congestion_control" = "bbr";
  boot.kernel.sysctl."net.core.default_qdisc" = "cake";
  ## END sysctl.nix

  ## BEGIN network.nix
  networking = {
    useNetworkd = true;
    nftables.enable = true;
    firewall = {
      # enable = false; # Disable firewall
      extraInputRules = ''
        # ip saddr 192.168.1.0/24 accept comment "Allow from LAN"
        ip6 saddr { fe80::/16, fd66:06e5:aebe::/48 } accept comment "Allow from Link-Local / ULA-Prefix (IPv6)"
        udp dport bootps accept comment "Allow DHCP server (systemd-nspawn)"
      '';
    };
    # Or `services.timesyncd.servers`
    timeServers = [
      "ntp.aliyun.com" # Aliyun NTP Server
      "ntp.tencent.com" # Tencent NTP Server
    ];
  };
  services.resolved.enable = true;

  # Auto detect the firewall type (nftables)
  systemd.services.tailscaled.environment.TS_DEBUG_FIREWALL_MODE = "auto";
  # Tailscale stores its data in /var/lib/tailscale, which is persistent across reboots via impermanence.nix
  # Ref: https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/networking/tailscale.nix
  services.tailscale = {
    openFirewall = true; # allow the Tailscale UDP port through the firewall
    useRoutingFeatures = "client"; # "server" if act as exit node
    # extraUpFlags = "--accept-routes";
    # authKeyFile = "/var/lib/tailscale/authkey";
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
  ## BEGIN shell.nix
  programs.zsh = {
    autosuggestions = {
      enable = true;
      highlightStyle = "fg=60";
      strategy = ["match_prev_cmd" "history" "completion"];
    };
    syntaxHighlighting.enable = true;
  };
  ## END shell.nix
  ## BEGIN users.nix
  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = false; # Don't allow mutate users outside the config
    groups = {
      # ${myvars.username} = {gid = 1000;};
      docker = {};
      storage = {gid = 1001;};
    };
    users.${myvars.username} = {
      # Public Keys that can be used to login to all my PCs, MacBooks, and servers.
      #
      # Since the authority range is pretty large, we must strengthen its security:
      # - The corresponding private key must be:
      #   1. Generated locally on every trusted client via:
      #     ```bash
      #     # KDF: bcrypt with 256 rounds, takes 2s on Apple M2):
      #     # Passphrase: digits + letters + symbols, 12+ chars
      #     ssh-keygen -t ed25519 -a 256 -C "ryan@xxx" -f ~/.ssh/xxx`
      #     ```
      #   2. Never leave the device and never sent over the network.
      # - Or just use hardware security keys like Yubikey/CanoKey.
      uid = 1000;
      home = "/home/${myvars.username}";
      # initialHashedPassword = myvars.initial_hashed_password;
      isNormalUser = true;
      extraGroups = [myvars.username "docker" "input" "libvirtd" "network" "video" "wheel"];
    };
    # root user are heavily used for remote NixOS deployment
    users.root = {
      # initialHashedPassword = config.users.users."${myvars.username}".initialHashedPassword;
      openssh.authorizedKeys.keys = config.users.users."${myvars.username}".openssh.authorizedKeys.keys;
    };
  };
  ## END users.nix
  ## BEGIN zram.nix
  zramSwap.enable = true;
  ## END zram.nix
  ## BEGIN power-management.nix
  systemd.services.console-blanking = {
    # Let monitor become blank after 2 mins, and 3 mins inactive to poweroff
    description = "Enable virtual console blanking and DPMS";
    after = ["display-manager.service"];
    environment.TERM = "linux";
    serviceConfig = {
      Type = "oneshot";
      StandardOutput = "tty";
      TTYPath = "/dev/console";
      ExecStart = "${lib.getExe' pkgs.util-linux "setterm"} --blank 2 --powerdown 3";
    };
    wantedBy = ["multi-user.target"];
  };
  ## END power-management.nix
  ## BEGIN fonts.nix
  # All fonts are linked to /nix/var/nix/profiles/system/sw/share/X11/fonts
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [noto-fonts noto-fonts-color-emoji];
    fontconfig = {
      subpixel.rgba = "rgb";
      defaultFonts = {
        serif = ["Noto Serif" "FZYaSongS-R-GB" "Noto Serif CJK SC" "Noto Serif CJK TC" "Noto Serif CJK JP"];
        sansSerif = ["Inter Nerd Font" "Noto Sans" "Noto Sans CJK SC" "Noto Sans CJK TC" "Noto Sans CJK JP"];
        monospace = [
          myvars.monospace.name
          "Noto Sans Mono"
          "Noto Sans Mono CJK SC"
          "Noto Sans Mono CJK TC"
          "Noto Sans Mono CJK JP"
        ];
        emoji = ["Noto Color Emoji"];
      };
    };
  };
  ## END fonts.nix
  ## BEGIN security.nix
  # Without polkit, sing-box can't interact with systemd-resolved
  security = {
    polkit.enable = true;
    sudo = {
      package = pkgs.sudo.override {withSssd = true;};
      extraConfig = ''Defaults passwd_timeout=0''; # Disable timeout for sudo prompt
    };
  };
  system.nssDatabases.sudoers = ["sss"]; # Use LDAP to distribute configuration of sudo as well
  sops = let
    restartUnits = ["sssd.service"];
    sopsFile = "${myvars.secrets_dir}/common.sops.yaml";
  in {
    secrets."sssd_ldap_default_authtok" = {inherit sopsFile restartUnits;};
    templates."sssd.env" = {
      # https://github.com/NixOS/nixpkgs/blob/15f4ee454b1dce334612fa6843b3e05cf546efab/nixos/modules/services/misc/sssd.nix#L111-L113
      inherit restartUnits;
      content = "SSSD_LDAP_DEFAULT_AUTHTOK='${config.sops.placeholder.sssd_ldap_default_authtok}'";
    };
  };
  services.sssd = {
    enable = true;
    environmentFile = config.sops.templates."sssd.env".path;
    settings = {
      sssd = {
        # debug_level = 7;
        services = "ifp, nss, pam, sudo";
        domains = "LDAP";
      };
      # "pam".pam_verbosity = 3;
      "domain/LDAP" = let
        base_dn = "dc=" + builtins.replaceStrings ["."] [",dc="] myvars.domain;
      in {
        override_shell = "/run/current-system/sw/bin/${config.users.defaultUserShell.meta.mainProgram}";
        cache_credentials = true;
        entry_cache_timeout = 600;
        enumerate = true;

        id_provider = "ldap";
        auth_provider = "ldap";
        chpass_provider = "ldap";

        ldap_uri = "ldaps://ldap.${myvars.domain}:636";
        ldap_default_bind_dn = "uid=sssd,ou=ServiceAccounts,${base_dn}";
        ldap_default_authtok = "$SSSD_LDAP_DEFAULT_AUTHTOK";
        ldap_search_base = base_dn;
        ldap_sudo_search_base = "ou=Sudoers,${base_dn}";
        ldap_tls_reqcert = "demand";
        ldap_network_timeout = 2;
        ldap_schema = "rfc2307bis";
      };
    };
  };
  ## END security.nix
}

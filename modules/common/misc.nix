{
  lib,
  myvars,
  pkgs,
  ...
}: {
  system.stateVersion =
    if pkgs.stdenv.isDarwin
    then myvars.darwin_state_version
    else myvars.nixos_state_version;
  # Add my self-signed CA certificate to the system-wide trust store.
  security.pki.certificateFiles = ["${myvars.secrets_dir}/proteus_ca.pub.pem"];
  nixpkgs.config.allowUnfree = true; # Allow chrome, vscode to install
  ## BEGIN nix.nix
  nix.package = pkgs.nixVersions.latest; # Use latest nix, default is pkgs.nix
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 7d";
  };
  nix.channel.enable = false; # Remove nix-channel related tools & configs, use flakes instead
  # Manual optimise storage: nix-store --optimise
  # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
  nix.optimise.automatic = true; # Add a timer to do optimise periodically
  nix.settings = {
    experimental-features = ["nix-command" "flakes"]; # Enable flakes globally
    trusted-users = [myvars.username];
    # Specify additional substituters via:
    # 1. `nixConfig.substituers` in `flake.nix`
    # 2. command line args `--options substituers http://xxx`
    substituters = [
      # Substituers that will be considered before the official ones (https://cache.nixos.org)
      # cache mirror located in China
      # "https://mirrors.ustc.edu.cn/nix-channels/store" # status: https://mirrors.ustc.edu.cn/status/
      # "https://mirror.sjtu.edu.cn/nix-channels/store" # status: https://mirror.sjtu.edu.cn/
      # Others
      "https://mirrors.sustech.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"

      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
    builders-use-substitutes = true;
    sandbox =
      if pkgs.stdenv.isDarwin
      then "relaxed" # KeePassXC
      else true;
    # The substituter will be appended to the default substituters when fetching packages.
    extra-substituters = ["https://nix-cache.s3-pub.${myvars.domain}/"];
    extra-trusted-public-keys = ["s3.${myvars.domain}-1:IxrRwk4uC5ittHeG9menkuajABnrX9cboEWwZz/m4+E="];
  };
  ## END nix.nix
  ## BEGIN i18n.nix
  # NOTE: On macOS, Please set [Set time zone automatically using your current location] to false in [System Settings]
  time.timeZone = lib.mkDefault "Asia/Hong_Kong";
  ## END i18n.nix
  ## BEGIN ssh.nix
  services.openssh.enable = true;
  programs.ssh = {
    # Configs will be written to /etc/ssh/ssh_config
    extraConfig = lib.mkMerge [
      (lib.mkBefore ''
        Compression yes
        ControlMaster auto
        ControlPath ~/.ssh/master-%r@%n:%p
        ControlPersist 30m
        ServerAliveInterval 30
        ServerAliveCountMax 5
      '')
      (lib.mkAfter (
        lib.foldlAttrs (acc: hostname: ifaces:
          acc
          + ''
            Host ${hostname}
              Hostname ${
              let
                ts_iface = builtins.elemAt ifaces 0;
                et_iface = lib.optionalAttrs (builtins.length ifaces >= 2) (builtins.elemAt ifaces 1);
              in
                if et_iface ? ipv4
                then et_iface.ipv4
                else if ts_iface ? ipv4
                then ts_iface.ipv4
                else hostname
            }
              Port 22
          '')
        ""
        myvars.networking.hosts_addr
      ))
    ];
    # Define the host key for remote builders so that Nix can verify all the remote builders.
    # This config will be written to /etc/ssh/ssh_known_hosts
    knownHosts =
      lib.mapAttrs (name: val: let
        ifaces = myvars.networking.hosts_addr.${name} or [];
        ts_iface = lib.optionalAttrs (ifaces != []) (builtins.elemAt ifaces 0);
        et_iface = lib.optionalAttrs (builtins.length ifaces >= 2) (builtins.elemAt ifaces 1);
      in {
        hostNames =
          [name] # Hostname and its IPv4 & IPv6
          ++ ((lib.optional (ts_iface ? ipv4) ts_iface.ipv4) ++ (lib.optional (ts_iface? ipv6) ts_iface.ipv6))
          ++ ((lib.optional (et_iface? ipv4) et_iface.ipv4) ++ (lib.optional (et_iface? ipv6) et_iface.ipv6));
        publicKey = val.public_key;
      })
      myvars.networking.known_hosts;
  };
  ## END ssh.nix
  ## BEGIN users.nix
  users.users.${myvars.username} = {
    description = myvars.userfullname;
    openssh.authorizedKeys.keys = myvars.ssh_authorized_keys;
  };
  ## END users.nix
  ## BEGIN tailscale.nix
  services.tailscale.enable = lib.mkDefault true; # Start-up: `tailscale up --accept-routes`
  ## END tailscale.nix
  ## BEGIN sing-box.nix
  # services.sing-box.package = pkgs.sing-box.overrideAttrs(final: _: {
  #   version = "1.13.0";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "SagerNet";
  #     repo = "sing-box";
  #     tag = "v${final.version}";
  #     # Use lib.fakeHash generate dummy hash
  #     hash = "sha256-lhkz/mXydZz5iJllqSp4skA4+jxs8oUmon/oFs98Zfc=";
  #   };
  #   vendorHash = "sha256-vVLaG0PV1OXA+YL67BnrHJiSkNVzJbZ8TeMKbO2rMu0=";
  # });
  ## END sing-box.nix
  ## BEGIN fonts.nix
  fonts.packages = with pkgs; [
    myvars.monospace.package
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    inter-nerdfont # NerdFont patch of the Inter font
    # nerdfonts
    # Ref: https://github.com/NixOS/nixpkgs/blob/nixos-unstable-small/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
    nerd-fonts.symbols-only # symbols icon only
  ];
  ## END fonts.nix
  ## BEGIN packages.nix
  environment.systemPackages = with pkgs; [
    ## Core Tools
    git # Used by nix flakes

    # Misc
    findutils
    tree
    gnutar
    rsync
    gnugrep # GNU grep, provides `grep`/`egrep`/`fgrep`
    curl
    # aria2 # A lightweight multi-protocol & multi-source command-line download utility
  ];
  ## END packages.nix
}

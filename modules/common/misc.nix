{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
{
  system.stateVersion = if pkgs.stdenv.isDarwin then myvars.darwinStateVersion else myvars.nixosStateVersion;

  # Add my self-signed CA certificate to the system-wide trust store.
  security.pki.certificateFiles = [ "${myvars.secretsDir}/proteus_ca.pub.pem" ];

  nixpkgs.config.allowUnfree = true; # Allow chrome, vscode to install

  ## BEGIN services_ssh.nix
  services.openssh = lib.mkMerge [
    { enable = true; }
    (lib.optionalAttrs (!pkgs.stdenv.isDarwin) { settings.PasswordAuthentication = lib.mkDefault false; }) # Disable password login
  ];
  ## END services_ssh.nix

  ## BEGIN i18n.nix
  # NOTE: On macOS, Please set [Set time zone automatically using your current location] to false in [System Settings]
  time.timeZone = lib.mkDefault myvars.timeZone;
  ## END i18n.nix
  ## BEGIN users.nix
  users = lib.mkMerge [
    {
      users.${myvars.username} = {
        description = myvars.userFullName;
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
        openssh.authorizedKeys.keys = myvars.sshAuthorizedKeys;
      };
    }
    (lib.mkIf (!pkgs.stdenv.isDarwin) {
      defaultUserShell = if config.programs.zsh.enable then pkgs.zsh else "/bin/sh";
      mutableUsers = false; # Don't allow mutate users outside the config
      groups.storage.gid = 1001;
      users.${myvars.username} = {
        uid = 1000;
        home = "/home/${myvars.username}";
        # initialHashedPassword = myvars.initial_hashed_password;
        isNormalUser = true;
        extraGroups = [
          "input"
          "network"
          "video"
          "wheel"
        ];
      };
      # root user are heavily used for remote NixOS deployment
      users.root = {
        # initialHashedPassword = config.users.users."${myvars.username}".initialHashedPassword;
        openssh.authorizedKeys.keys = config.users.users."${myvars.username}".openssh.authorizedKeys.keys;
      };
    })
    (lib.mkIf pkgs.stdenv.isDarwin {
      users.users.${myvars.username} = {
        home = "/Users/${myvars.username}"; # home-manager needs it
        # nix-darwin doesn't have `users.defaultUserShell`. If this don't work, try
        # `chsh -s /run/current-system/sw/bin/zsh`
        shell = pkgs.zsh;
      };
    })
  ];
  ## END users.nix
  ## BEGIN tailscale.nix
  # Start-up: `tailscale up --accept-routes`
  services.tailscale = lib.mkMerge [
    { enable = lib.mkDefault true; }
    (lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
      # Tailscale stores its data in /var/lib/tailscale, which is persistent across reboots via impermanence.nix
      # Ref: https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/networking/tailscale.nix
      openFirewall = true; # allow the Tailscale UDP port through the firewall
      useRoutingFeatures = "client"; # "server" if act as exit node
      # extraUpFlags = "--accept-routes";
      # authKeyFile = "/var/lib/tailscale/authkey";
    })
  ];
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
}

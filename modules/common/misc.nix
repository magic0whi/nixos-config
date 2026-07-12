{
  config,
  lib,
  const,
  pkgs,
  ...
}:
{
  system.stateVersion = if pkgs.stdenv.isDarwin then const.darwinStateVersion else const.nixosStateVersion;

  # Add my self-signed CA certificate to the system-wide trust store.
  security.pki.certificateFiles = [ "${const.secretsDir}/proteus_ca.pub.pem" ];

  nixpkgs.config.allowUnfree = true; # Allow chrome, vscode to install

  ## BEGIN services_ssh.nix
  services.openssh = lib.mkMerge [
    { enable = true; }
    (lib.optionalAttrs (!pkgs.stdenv.isDarwin) { settings.PasswordAuthentication = lib.mkDefault false; }) # Disable password login
  ];
  ## END services_ssh.nix

  ## BEGIN i18n.nix
  # NOTE: On macOS, Please set [Set time zone automatically using your current location] to false in [System Settings]
  time.timeZone = lib.mkDefault const.timeZone;
  ## END i18n.nix
  ## BEGIN users.nix
  users = lib.mkMerge [
    {
      groups.storage.gid = 1001;
      # NOTE: fixes /etc/udev/rules.d/60-openocd.rules: Failed to resolve group 'plugdev', ignoring: Unknown group
      groups.plugdev = { };
      # root user are heavily used for remote NixOS deployment
      users = {
        root = {
          # initialHashedPassword = config.users.users."${const.username}".initialHashedPassword;
          openssh.authorizedKeys.keys = config.users.users."${const.username}".openssh.authorizedKeys.keys;
        };
        ${const.username} = {
          description = const.userFullName;
          uid = if pkgs.stdenv.isDarwin then 501 else 1000;
          # home-manager needs it
          home = if pkgs.stdenv.isDarwin then "/Users/${const.username}" else "/home/${const.username}";
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
          openssh.authorizedKeys.keys = const.sshAuthorizedKeys;
        };
      };
    }
    (lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
      defaultUserShell = if config.programs.zsh.enable then pkgs.zsh else "/bin/sh";
      mutableUsers = false; # Don't allow mutate users outside the config
      users.${const.username} = {
        # initialHashedPassword = const.initial_hashed_password;
        isNormalUser = true;
        extraGroups = [
          "input"
          "network"
          "video"
          "wheel"
        ];
      };
    })
    (lib.mkIf pkgs.stdenv.isDarwin {
      users.${const.username} = {
        # nix-darwin doesn't have `users.defaultUserShell`. If this don't work, try
        # `chsh -s /run/current-system/sw/bin/zsh`
        shell = pkgs.zsh;
      };
    })
  ];
  ## END users.nix
}

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
      groups.storage.gid = 1001;
      # root user are heavily used for remote NixOS deployment
      users = {
        root = {
          # initialHashedPassword = config.users.users."${myvars.username}".initialHashedPassword;
          openssh.authorizedKeys.keys = config.users.users."${myvars.username}".openssh.authorizedKeys.keys;
        };
        ${myvars.username} = {
          description = myvars.userFullName;
          uid = if pkgs.stdenv.isDarwin then 501 else 1000;
          # home-manager needs it
          home = if pkgs.stdenv.isDarwin then "/Users/${myvars.username}" else "/home/${myvars.username}";
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
      };
    }
    (lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
      defaultUserShell = if config.programs.zsh.enable then pkgs.zsh else "/bin/sh";
      mutableUsers = false; # Don't allow mutate users outside the config
      users.${myvars.username} = {
        # initialHashedPassword = myvars.initial_hashed_password;
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
      users.${myvars.username} = {
        # nix-darwin doesn't have `users.defaultUserShell`. If this don't work, try
        # `chsh -s /run/current-system/sw/bin/zsh`
        shell = pkgs.zsh;
      };
    })
  ];
  ## END users.nix
}

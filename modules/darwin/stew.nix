{
  config,
  lib,
  myvars,
  pkgs,
  ...
}: {
  ## BEGIN networking.nix
  networking = {
    knownNetworkServices = ["Wi-Fi"]; # List of networkservices that should be configured.
    # sing-box requires a non-local address to hijack DNS
    dns = [
      "223.5.5.5"
      # "2400:3200::1"
      # "8.8.8.8"
    ];
  };
  ## END networking.nix
  ## BEGIN ssh.nix
  # Disable password authentication for SSH
  environment.etc."ssh/sshd_config.d/200-disable-password-auth.conf".text = ''
    PasswordAuthentication no
    KbdInteractiveAuthentication no
  '';
  ## END ssh.nix
  ## BEGIN security.nix
  security.pam.services.sudo_local.touchIdAuth = true; # Add ability to used TouchID for sudo authentication

  # NOTE: `nix-darwin` only executes hardcoded list of script names during the rebuild process
  # https://github.com/nix-darwin/nix-darwin/issues/663
  # system.activationScripts.trust_custom_ca.text = ''
  system.activationScripts.postActivation.text = ''
    ## BEGIN ACTIVATION SCRIPT trust_custom_ca.sh
    echo "Checking self-signed CA in macOS System Keychain..."

    CA_CERT="${myvars.secrets_dir}/proteus_ca.pub.pem"
    CA_NAME="Homo home"

    # 1. Get the SHA-1 fingerprint of current self-signed certificate file on disk
    # We use awk to just grab the hex part and remove the colons so it matches macOS output
    DISK_FINGERPRINT=$(${lib.getExe pkgs.openssl} x509 -in "$CA_CERT" -noout -fingerprint -sha1 | awk -F '=' '{print $2}' | tr -d ':')

    # 2. Lookup SHA-1 fingerprint of self-signed certificate in the macOS Keychain by its name
    KEYCHAIN_FINGERPRINT=$(/usr/bin/security find-certificate -c "$CA_NAME" -Z /Library/Keychains/System.keychain 2>/dev/null | grep "SHA-1 hash:" | awk '{print $3}')

    if [ -z "$KEYCHAIN_FINGERPRINT" ]; then
      echo "Certificate not found in Keychain. Installing..."
      sudo /usr/bin/security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CA_CERT"
    elif [ "$DISK_FINGERPRINT" != "$KEYCHAIN_FINGERPRINT" ]; then
      echo "Certificate renewal detected! Updating Keychain..."
      sudo /usr/bin/security delete-certificate -Z "$KEYCHAIN_FINGERPRINT" /Library/Keychains/System.keychain
      sudo /usr/bin/security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CA_CERT"
    else
      echo "Current CA is already trusted and up to date."
    fi
    ## END ACTIVATION SCRIPT trust_custom_ca.sh
  '';
  ## END security.nix
  ## BEGIN shell.nix
  environment.shells = [config.users.users.${myvars.username}.shell]; # Permissible login shells
  programs.zsh.enableSyntaxHighlighting = true;
  ## END shell.nix
  ## BEGIN users.nix
  system.primaryUser = myvars.username;
  users.users.${myvars.username} = {
    home = "/Users/${myvars.username}"; # home-manager needs it
    # nix-darwin doesn't have `users.defaultUserShell`. If this don't work, try
    # `chsh -s /run/current-system/sw/bin/zsh`
    shell = pkgs.zsh;
  };
  ## END users.nix
}

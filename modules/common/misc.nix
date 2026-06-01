{
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
  users.users.${myvars.username} = {
    description = myvars.userFullName;
    openssh.authorizedKeys.keys = myvars.sshAuthorizedKeys;
  };
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

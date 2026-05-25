{
  lib,
  myvars,
  pkgs,
  ...
}:
{
  system.stateVersion = if pkgs.stdenv.isDarwin then myvars.darwin_state_version else myvars.nixos_state_version;

  # Add my self-signed CA certificate to the system-wide trust store.
  security.pki.certificateFiles = [ "${myvars.secrets_dir}/proteus_ca.pub.pem" ];

  nixpkgs.config.allowUnfree = true; # Allow chrome, vscode to install

  services.openssh.enable = true;
  ## BEGIN nix.nix
  environment.systemPackages = [ pkgs.git ]; # Required by flake
  nix = {
    package = pkgs.nixVersions.latest; # Use latest nix, default is pkgs.nix
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux { dates = "weekly"; };
    channel.enable = false; # Remove nix-channel related tools & configs, use flakes instead
    # Manual optimise storage: nix-store --optimise
    # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
    optimise.automatic = true; # Add a timer to do optimise periodically
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ]; # Enable flakes globally
      trusted-users = [ myvars.username ];
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
      trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
      builders-use-substitutes = true;
      sandbox =
        if pkgs.stdenv.isDarwin then
          "relaxed" # KeePassXC
        else
          true;
      # The substituter will be appended to the default substituters when fetching packages.
      extra-substituters = [ "https://nix-cache.s3-pub.${myvars.domain}/" ];
      extra-trusted-public-keys = [ "s3.${myvars.domain}-1:IxrRwk4uC5ittHeG9menkuajABnrX9cboEWwZz/m4+E=" ];
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux { auto-optimise-store = true; }; # Optimise the store after each build
  };
  ## END nix.nix
  ## BEGIN i18n.nix
  # NOTE: On macOS, Please set [Set time zone automatically using your current location] to false in [System Settings]
  time.timeZone = lib.mkDefault "Asia/Hong_Kong";
  ## END i18n.nix
  ## BEGIN users.nix
  users.users.${myvars.username} = {
    description = myvars.userfullname;
    openssh.authorizedKeys.keys = myvars.ssh_authorized_keys;
  };
  ## END users.nix
  ## BEGIN tailscale.nix
  services.tailscale = {
    enable = lib.mkDefault true;
  } # Start-up: `tailscale up --accept-routes`
  // lib.optionalAttrs pkgs.stdenv.isLinux {
    # Tailscale stores its data in /var/lib/tailscale, which is persistent across reboots via impermanence.nix
    # Ref: https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/networking/tailscale.nix
    openFirewall = true; # allow the Tailscale UDP port through the firewall
    useRoutingFeatures = "client"; # "server" if act as exit node
    # extraUpFlags = "--accept-routes";
    # authKeyFile = "/var/lib/tailscale/authkey";
  };
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

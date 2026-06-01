{ lib, pkgs, ... }:
{
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
}

# https://github.com/nixpak/pkgs/blob/master/pkgs/modules/network.nix
{ lib, ... }:
{
  etc.sslCertificates.enable = true;
  bubblewrap.network = true;
  # pasta's default isolate mode gives the app its own loopback, so host
  # services on 127.0.0.1 are out of reach. Proxying still works because
  # sing-box runs in TUN mode, which sees pasta's outbound traffic.
  #
  # Set `pasta.enable = false` in a policy to fall back to sharing the host
  # network namespace if an app cannot cope with pasta.
  pasta.enable = lib.mkDefault true;
}

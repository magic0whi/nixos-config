# Derive LiveCD from a machine's config is a bad idea, so I use a standalone machine config instead
{ const, ... }:
{
  # Useful when generating image from an existing NixOS configuration
  # image.modules = {
  #   example =
  #     { pkgs, ... }:
  #     {
  #       isoImage.compressImage = false;

  #       # Add specific packages only to the live CD
  #       environment.systemPackages = with pkgs; [
  #         parted
  #         git
  #         neovim
  #       ];
  #     };
  # };

  security.sudo.wheelNeedsPassword = false;
  security.sudo-rs.wheelNeedsPassword = false;
  services.openssh.settings = {
    PasswordAuthentication = true;
    PermitRootLogin = "yes";
  };
  isoImage = {
    compressImage = true;
    makeEfiBootable = true;
  };
  services.greetd.settings =
    let
      command = ''sh -c \"$HOME/.wayland-session\"'';
    in
    {
      # initial_session defines the auto-login behavior on boot
      initial_session = {
        inherit command;
        user = const.username;
      };
      default_session = {
        inherit command;
        user = const.username;
      };
    };
  services.gnome.gnome-keyring.enable = false;
}

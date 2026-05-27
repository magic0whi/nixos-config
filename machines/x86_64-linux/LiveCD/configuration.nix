{
  config,
  myvars,
  ...
}:
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
  boot.loader.systemd-boot.enable = false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl"; # sudo sbctl create-keys
    # allowUnsigned = true; # Useful for first boot
  };
  security.sudo.wheelNeedsPassword = false;
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
        user = myvars.username;
      };
      default_session = {
        inherit command;
        user = myvars.username;
      };
    };
  services.gnome.gnome-keyring.enable = false;
  ## BEGIN iwd.nix
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings.General.Country = "US";
  systemd.services.iwd.serviceConfig.ExecStart = [
    # Leave an empty string to remove previous ExecStarts
    ""
    "${config.networking.wireless.iwd.package}/libexec/iwd --nointerfaces 'wlan[0-9]'"
  ];
  systemd.network.links."80-iwd".enable = false;
  ## END iwd.nix
}

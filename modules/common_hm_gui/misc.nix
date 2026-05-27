{ lib, pkgs, ... }:
{
  ## BEGIN browsers.nix
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/chromium.nix
  programs.google-chrome = lib.mkIf (!pkgs.stdenv.isDarwin) {
    enable = true;
    # https://wiki.archlinux.org/title/Chromium#Native_Wayland_support
    commandLineArgs = [
      "--ozone-platform-hint=auto"
      "--enable-wayland-ime" # Make it use text-input-v1, which works for kwin 5.27 and weston
      # "--enable-features=Vulkan" # Enable hardware acceleration - vulkan api
    ];
  };
  programs.firefox.enable = true;
  ## END browsers.nix
  ## BEGIN vscode.nix
  # programs.vscode = {
  #   enable = true;
  #   # Use gnome-keyring as password store
  #   package = if pkgs.stdenv.isLinux
  #   then pkgs.vscode.override {commandLineArgs = ["--password-store=gnome"];}
  #   else pkgs.vscode;
  #   # Let vscode sync and update its configuration & extensions across devices, using github account
  #   profiles.default.userSettings = {};
  # };
  # programs.joplin-desktop.enable = true; # Note taking app, https://joplinapp.org/help/
  ## END vscode.nix
}

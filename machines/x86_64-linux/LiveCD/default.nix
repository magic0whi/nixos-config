{
  mylib,
  myvars,
  nixpkgs,
  ...
}:
let
  name = baseNameOf ./.;
  nixpkgs_modules = map mylib.relativeToRoot [
    "modules/common/fonts.nix"
    "modules/common/misc.nix"
    "modules/common/packages.nix"
    "modules/common/shell.nix"
    "modules/common/ssh.nix"

    "modules/nixos_headless/fhs.nix"
    "modules/nixos_headless/krnl-compat.nix"
    "modules/nixos_headless/misc.nix"
    "modules/nixos_headless/packages.nix"
    "modules/nixos_headless/power-mgmt.nix"
    "modules/nixos_headless/scx-loader.nix"
    "modules/nixos_headless/zfs.nix"

    "modules/nixos_gui/kmscon.nix"
    "modules/nixos_gui/peripherals.nix"
    "modules/nixos_gui/wayland.nix"
  ];
  hm_modules = map mylib.relativeToRoot [
    "modules/common_hm_headless/helix.nix"
    "modules/common_hm_headless/misc.nix"
    "modules/common_hm_headless/packages.nix"
    "modules/common_hm_headless/shell.nix"
    "modules/common_hm_headless/zellij.nix"

    "modules/common_hm_gui/alacritty.nix"
    "modules/common_hm_gui/ghostty.nix"
    "modules/common_hm_gui/misc.nix"
    "modules/common_hm_gui/mpv.nix"
    "modules/common_hm_gui/packages.nix"
    "modules/common_hm_gui/pdf_reader.nix"

    "modules/nixos_hm_headless/peripherals.nix"

    "modules/nixos_hm_gui/fcitx5.nix"
    "modules/nixos_hm_gui/gammastep.nix"
    "modules/nixos_hm_gui/gtk_and_qt.nix"
    "modules/nixos_hm_gui/hyprland"
    "modules/nixos_hm_gui/xdg.nix"
  ];
  nixos_system = nixpkgs.lib.nixosSystem (
    mylib.genOsConfiguration {
      inherit
        name
        mylib
        myvars
        nixpkgs_modules
        hm_modules
        ;
      machine_path = ./.;
    }
  );
in
{
  _DEBUG = {
    inherit
      name
      nixpkgs_modules
      hm_modules
      myvars
      mylib
      nixos_system
      ;
  };
  packages.${name} = nixos_system.config.system.build.isoImage;
  # Useful when generating image from an existing NixOS configuration
  # packages.${name} = nixos_system.config.system.build.images.iso; # generate iso image
}

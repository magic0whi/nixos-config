{
  mylib,
  myvars,
  features,

  deploy-rs,
  nixpkgs,
  noctalia-greeter,
  ...
}:
let
  name = baseNameOf ./.;
  nixos_system = nixpkgs.lib.nixosSystem (
    mylib.genOsConfiguration {
      inherit
        name
        mylib
        myvars
        ;
      machinePath = ./.;
      specialArgs = { inherit deploy-rs; };
      overlays = features.nixos.seat.guiOverlays;
      modules =
        let
          common = "modules/common";
          headless = "modules/nixos_headless";
          gui = "modules/nixos_gui";
        in
        map mylib.relativeToRoot [
          "${common}/fonts.nix"
          "${common}/misc.nix"
          "${common}/packages.nix"
          "${common}/shell.nix"
          "${common}/ssh.nix"
        ]
        ++ [ noctalia-greeter.nixosModules.default ]
        ++ map mylib.relativeToRoot [
          "${headless}/fhs.nix"
          "${headless}/iwd.nix"
          "${headless}/krnl-compat.nix"
          "${headless}/misc.nix"
          "${headless}/packages.nix"
          "${headless}/power-mgmt.nix"
          "${headless}/scx-loader.nix"
          "${headless}/zfs.nix"

          "${gui}/kmscon.nix"
          "${gui}/peripherals.nix"
          "${gui}/wayland.nix"
        ];
      hmModules =
        let
          commonHmHeadless = "modules/common_hm_headless";
          commonHmGui = "modules/common_hm_gui";
          nixosHmGui = "modules/nixos_hm_gui";
        in
        features.hm.common.base
        ++ map mylib.relativeToRoot [
          "${commonHmHeadless}/helix.nix"
          "${commonHmHeadless}/misc.nix"
          "${commonHmHeadless}/packages.nix"
          "${commonHmHeadless}/shell.nix"
          "${commonHmHeadless}/zellij.nix"

          "${commonHmGui}/alacritty.nix"
          "${commonHmGui}/ghostty.nix"
          "${commonHmGui}/misc.nix"
          "${commonHmGui}/mpv.nix"
          "${commonHmGui}/packages.nix"
          "${commonHmGui}/pdf_reader.nix"

          "modules/nixos_hm_headless/peripherals.nix"

          "${nixosHmGui}/fcitx5.nix"
          "${nixosHmGui}/gammastep.nix"
          "${nixosHmGui}/gtk_and_qt.nix"
          "${nixosHmGui}/hyprland"
          "${nixosHmGui}/xdg.nix"
        ];
    }
  );
in
{
  _DEBUG = { inherit name nixos_system; };
  packages.${name} = nixos_system.config.system.build.isoImage;
  # Useful when generating image from an existing NixOS configuration
  # packages.${name} = nixos_system.config.system.build.images.iso; # generate iso image
}

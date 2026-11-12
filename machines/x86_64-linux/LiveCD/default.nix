{
  mylib,
  const,
  features,

  deploy-rs,
  impermanence,
  nixpkgs,
  noctalia-greeter,
  ...
}:
let
  name = baseNameOf ./.;
  nixos_system = nixpkgs.lib.nixosSystem (
    mylib.mkOsConfiguration {
      inherit
        name
        mylib
        const
        ;
      machinePath = ./.;
      specialArgs = { inherit deploy-rs; };
      overlays = with features; common.baseOverlays ++ nixos.seat.guiOverlays;
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
        ++ [
          # Shared modules declare persistent dirs; keep the option but mount nothing on the live ISO
          impermanence.nixosModules.default
          {
            environment.persistence."/persistent".enable = false;
            home-manager.sharedModules = [ { home.persistence."/persistent".enable = false; } ];
          }
          noctalia-greeter.nixosModules.default
        ]
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
          "${commonHmGui}/misc.nix"
          "${commonHmGui}/packages.nix"

          "modules/nixos_hm_headless/udiskie.nix"

          "${nixosHmGui}/fcitx5.nix"
          "${nixosHmGui}/theming.nix"
          "${nixosHmGui}/niri"
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

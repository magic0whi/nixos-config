{
  lib,
  mylib,
  myvars,
  nixos-hardware,
  nixpkgs,
  ...
}:
let
  name = baseNameOf ./.;
  nixpkgs_modules = map mylib.relativeToRoot [
    "modules/secrets"

    # "modules/common/easytier.nix"
    "modules/common/misc.nix"
    "modules/common/shell.nix"
    # "modules/common/nix.nix"

    "modules/nixos_headless/firewall.nix"
    # "modules/nixos_headless/impermanence.nix"
    "modules/nixos_headless/misc.nix"
    "modules/nixos_headless/niks3-auto-upload.nix"
    # "modules/nixos_headless/scx-loader.nix"
    # "modules/nixos_headless/systemd-resolved.nix"
    # "modules/nixos_headless/traffic-quota.nix"
  ];
  nixos_system = nixpkgs.lib.nixosSystem (
    mylib.genOsConfiguration {
      inherit
        name
        mylib
        myvars
        nixpkgs_modules
        ;
      machine_path = ./.;
    }
  );
  nixos_sd_image = nixpkgs.lib.nixosSystem (
    mylib.genOsConfiguration {
      inherit
        name
        mylib
        myvars
        ;
      machine_path = ./.;
      nixpkgs_modules = nixpkgs_modules ++ [
        {
          # Cross-compile, either
          # nixpkgs.buildPlatform = "x86_64-linux";
          # Or add `boot.binfmt.emulatedSystems = ["riscv64-linux"];` to your NixOS configurations
          # disko.enableConfig = false; # nixpkgs' sd-image.nix use its built-in ext4
          imports = [ "${nixos-hardware}/starfive/visionfive/v2/sd-image-installer.nix" ];
          sdImage.compressImage = false;

          users.users.nixos.password = "test123";

          networking.interfaces.end0.useDHCP = true;
          networking.interfaces.end1.useDHCP = true;

          security.sudo-rs.enable = lib.mkForce false;
        }
      ];
    }
  );
in
{
  _DEBUG = {
    inherit
      name
      nixpkgs_modules
      myvars
      mylib
      nixos_system
      ;
  };
  nixos_configurations.${name} = nixos_system;
  # packages.${name} = nixos_sd_image.config.system.build.images.sd-card; # Generate iso image
  packages.${name} = nixos_sd_image.config.system.build.sdImage;
  deploy-rs_node.${name} = mylib.genDeployNode myvars.networking.hostAddrs.${name} nixos_system;
}

{
  lib,
  mylib,
  const,
  nixos-hardware,
  nixpkgs,
  disko,
  ...
}:
let
  name = baseNameOf ./.;
  # TODO: import common modules here is bad practice, blacklist from
  # `const.features` instead
  modules = map mylib.relativeToRoot [
    "modules/variables/host-addrs.nix"
    # "modules/common/easytier.nix"
    # "modules/common/misc.nix"
    # "modules/common/nix.nix"
    # "modules/common/secrets.nix"
    # "modules/common/shell.nix"
    # "modules/common/ssh.nix"

    # "modules/nixos_headless/firewall.nix"
    # "modules/nixos_headless/impermanence.nix"
    # "modules/nixos_headless/misc.nix"
    # "modules/nixos_headless/niks3-auto-upload.nix"
    # "modules/nixos_headless/scx-loader.nix"
    # "modules/nixos_headless/systemd-resolved.nix"
    # "modules/nixos_headless/traffic-quota.nix"
  ];
  nixos_cfg = nixpkgs.lib.nixosSystem (
    mylib.genOsConfiguration {
      inherit
        name
        mylib
        const
        ;
      modules =
        modules
        ++ [
          disko.nixosModules.disko
          nixos-hardware.nixosModules.starfive-visionfive-2
        ]
        ++ [
          {
            nixpkgs.overlays = [
              (_final: prev: {
                # Python 3.13 is the current default python3 in nixpkgs unstable
                python3 = prev.python3.override {
                  packageOverrides = _pyfinal: pyprev: {
                    numpy = pyprev.numpy.overridePythonAttrs (_oldAttrs: {
                      doCheck = false;
                    });
                  };
                };
                # Also override python313 explicitly in case any package references it directly
                python313 = prev.python313.override {
                  packageOverrides = _pyfinal: pyprev: {
                    numpy = pyprev.numpy.overridePythonAttrs (_oldAttrs: {
                      doCheck = false;
                    });
                  };
                };
              })
            ];
          }
        ];
      machinePath = ./.;
    }
  );
  nixos_sd_image = nixpkgs.lib.nixosSystem (
    mylib.genOsConfiguration {
      inherit
        name
        mylib
        const
        ;
      machinePath = ./.;
      modules = modules ++ [
        {
          # Cross-compile, either
          # nixpkgs.buildPlatform = "x86_64-linux";
          # Or add `boot.binfmt.emulatedSystems = ["riscv64-linux"];` to your NixOS configurations
          # disko.enableConfig = false; # nixpkgs' sd-image.nix use its built-in ext4
          imports = [ "${nixos-hardware}/starfive/visionfive/v2/sd-image-installer.nix" ];
          sdImage.compressImage = false;

          users.users.nixos.password = "test123";

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
      modules
      ;
  };
  nixos_configurations.${name} = nixos_cfg;
  # packages.${name} = nixos_sd_image.config.system.build.images.sd-card; # Generate iso image
  packages.${name} = nixos_sd_image.config.system.build.sdImage;
  deploy_nodes.${name} = mylib.genDeployNode nixos_cfg.config.vars.hostAddrs.${name} nixos_cfg;
}

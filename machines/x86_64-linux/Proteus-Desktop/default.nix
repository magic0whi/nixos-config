{
  machineConfigs,
  mylib,
  const,
  features,

  niks3,
  nixpkgs,
  # nixpkgs-old,
  sops-nix,
  dns,
  ...
}:
let
  name = baseNameOf ./.;
  nixosCfg = nixpkgs.lib.nixosSystem (
    mylib.genOsConfiguration {
      inherit
        name
        machineConfigs
        mylib
        const
        ;
      machinePath = ./.;
      specialArgs = {
        inherit dns;
        # pkgs-old = nixpkgs-old.legacyPackages.x86_64-linux;
      };
      overlays =
        (with features; common.baseOverlays)
        ++ nixpkgs.lib.singleton (
          _: prev: {
            # NOTE: This fixes authelia-web-pnpm-deps hash mismach
            authelia = prev.authelia.override {
              authelia-web = prev.authelia.web.overrideAttrs (old: {
                # pnpm_12 12.3.4 -> 12.9.0 changed the pnpm-deps output
                pnpmDeps = old.pnpmDeps.overrideAttrs { outputHash = "sha256-zIaVEjbh/LIQMqnryrgVm+46GP+9gM91WCMyAqeDnaA="; };
              });
            };
          }
        );
      modules =
        (with features.common; base ++ seat)
        ++ (with features.nixos; base ++ seat.tui)
        ++ [ niks3.nixosModules.niks3 ]
        ++ (map mylib.relativeToRoot [
          "modules/nixos_headless/krnl-compat.nix"
          "modules/nixos_headless/packages.nix"
          "modules/nixos_headless/zfs.nix"

          "modules/services/docker.nix"
          "modules/services/traefik.nix"
          "modules/services/prometheus-exporters.nix"
          "modules/services/garage.nix"
          "modules/services/darknet.nix"
          "modules/services/restic.nix"
        ]);
      hmModules =
        features.hm.common.base
        ++ [ sops-nix.homeManagerModules.sops ]
        ++ map mylib.relativeToRoot [ "modules/common_hm_headless/nix.nix" ];
    }
  );
in
{
  _DEBUG = { inherit name; };
  nixos_configurations.${name} = nixosCfg;
  deploy_nodes.${name} = mylib.genDeployNode {
    nics = nixosCfg.config.vars.hostAddrs.${name};
    inherit nixosCfg;
  };
}

{
  machineConfigs,
  mylib,
  const,
  features,

  niks3,
  nixpkgs,
  sops-nix,
  dns,
  ...
}:
let
  name = baseNameOf ./.;
  nixos_system = nixpkgs.lib.nixosSystem (
    mylib.genOsConfiguration {
      inherit
        name
        machineConfigs
        mylib
        const
        ;
      machinePath = ./.;
      specialArgs = { inherit dns; };
      overlays = with features; common.baseOverlays;
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
  nixos_configurations.${name} = nixos_system;
  deploy_nodes.${name} = mylib.genDeployNode const.networking.hostAddrs.${name} nixos_system;
}

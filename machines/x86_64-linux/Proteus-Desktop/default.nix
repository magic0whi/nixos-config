{
  machineConfigs,
  mylib,
  mypkg,
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
  nixosCfg = nixpkgs.lib.nixosSystem (
    mylib.mkOsConfiguration {
      inherit
        name
        machineConfigs
        mylib
        mypkg
        const
        ;
      machinePath = ./.;
      specialArgs = { inherit dns; };
      overlays = (with features; common.baseOverlays);
      modules =
        (with features.common; base ++ seat)
        ++ (with features.nixos; base ++ seat.tui)
        ++ [ niks3.nixosModules.niks3 ]
        ++ (map mylib.relativeToRoot [
          "modules/nixos_headless/krnl-compat.nix"
          "modules/nixos_headless/packages.nix"
          "modules/nixos_headless/zfs.nix"

          "modules/services/authelia-online.nix"
          "modules/services/darknet.nix"
          "modules/services/docker.nix"
          "modules/services/garage.nix"
          "modules/services/ldap-online.nix"
          "modules/services/prometheus-exporters.nix"
          "modules/services/restic.nix"
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
  nixos_configurations.${name} = nixosCfg;
  deploy_nodes.${name} = mylib.mkDeployNode {
    nics = nixosCfg.config.vars.hostAddrs.${name};
    inherit nixosCfg;
  };
}

{
  machineConfigs,
  mylib,
  myvars,
  nixpkgs,
  ...
}:
let
  name = baseNameOf ./.;
  nixpkgs_modules =
    myvars.base.nixpkgs_modules
    ++ (map mylib.relativeToRoot [
      "modules/nixos_headless/krnl-compat.nix"
      "modules/nixos_headless/packages.nix"
      "modules/nixos_headless/zfs.nix"

      "modules/nixos_gui/kmscon.nix"

      "modules/services/docker.nix"
      "modules/services/traefik.nix"
    ]);
  hm_modules = map mylib.relativeToRoot [
    "modules/common_hm_headless/helix.nix"
    "modules/common_hm_headless/misc.nix"
    "modules/common_hm_headless/nix.nix"
    "modules/common_hm_headless/shell.nix"
  ];
  desktop_myvars = myvars;
  nixos_system = nixpkgs.lib.nixosSystem (
    mylib.genOsConfiguration {
      inherit
        name
        machineConfigs
        mylib
        nixpkgs_modules
        hm_modules
        ;
      myvars = desktop_myvars;
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
  nixos_configurations.${name} = nixos_system;
  deploy-rs_nodes.${name} = mylib.genDeployNode myvars.networking.hostAddrs.${name} nixos_system;
}

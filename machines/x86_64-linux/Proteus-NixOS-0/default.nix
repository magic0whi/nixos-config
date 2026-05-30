{
  lib,
  machineConfigs,
  mylib,
  myvars,
  ...
}:
let
  inherit (myvars.base)
    nixpkgs_modules
    # hm_modules
    ;
  name = baseNameOf ./.;
  nixos_system = lib.nixosSystem (
    mylib.genOsConfiguration {
      inherit
        name
        mylib
        myvars
        machineConfigs
        nixpkgs_modules
        # hm_modules
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
      myvars
      mylib
      nixos_system
      ;
  };
  nixos_configurations.${name} = nixos_system;
  deploy-rs_node.${name} = mylib.genDeployNode myvars.networking.hostAddrs.${name} nixos_system;
}

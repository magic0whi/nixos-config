{
  lib,
  mylib,
  myvars,
  ...
}:
let
  inherit (myvars.base) nixpkgs_modules;
  name = baseNameOf ./.;
  nixos_system = lib.nixosSystem (
    mylib.gen_system_args {
      inherit
        name
        mylib
        myvars
        nixpkgs_modules
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
  deploy-rs_node.${name} = mylib.gen_deploy-rs_node myvars.networking.hosts_addr.${name} nixos_system;
}

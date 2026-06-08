{
  machineConfigs,
  mylib,
  myvars,
  nixpkgs,
  ...
}:
let
  nixpkgs_modules = myvars.base.nixpkgs_modules ++ [ ./_common ];
  names = map (p: baseNameOf p) (mylib.scanPath ./.);
  nixos_configurations =
    let
      gen_nixos_system =
        name:
        nixpkgs.lib.nixosSystem (
          mylib.genOsConfiguration {
            inherit
              name
              mylib
              myvars
              machineConfigs
              nixpkgs_modules
              # hm_modules
              ;
            machine_path = ./${name};
          }
        );
    in
    builtins.foldl' (acc: name: acc // { ${name} = gen_nixos_system name; }) { } names;
in
{
  _DEBUG = {
    inherit
      names
      nixpkgs_modules
      myvars
      mylib
      ;
  };
  inherit nixos_configurations;
  packages = builtins.mapAttrs (_: nixos_system: nixos_system.config.system.build.diskoImages) nixos_configurations;
  deploy-rs_nodes = builtins.mapAttrs (
    name: nixos_system: mylib.genDeployNode myvars.networking.hostAddrs.${name} nixos_system
  ) nixos_configurations;
}

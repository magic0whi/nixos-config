{
  machineConfigs,
  mylib,
  myvars,
  features,
  nixpkgs,
  ...
}:
let
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
              ;
            machinePath = ./${name};
            modules =
              features.common.base
              ++ features.nixos.base
              ++ map mylib.relativeToRoot [ "modules/nixos_headless/traffic-quota.nix" ]
              ++ [ ./_common ];
          }
        );
    in
    builtins.foldl' (acc: name: acc // { ${name} = gen_nixos_system name; }) { } names;
in
{
  _DEBUG = { inherit names; };
  inherit nixos_configurations;
  packages = builtins.mapAttrs (_: nixos_cfg: nixos_cfg.config.system.build.diskoImages) nixos_configurations;
  deploy_nodes = builtins.mapAttrs (
    name: nixos_cfg: mylib.genDeployNode myvars.networking.hostAddrs.${name} nixos_cfg
  ) nixos_configurations;
}

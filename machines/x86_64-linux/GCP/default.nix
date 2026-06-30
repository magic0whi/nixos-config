{
  machineConfigs,
  mylib,
  const,
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
              const
              machineConfigs
              ;
            machinePath = ./${name};
            overlays = with features; common.baseOverlays;
            modules =
              (with features; common.base ++ common.services ++ nixos.base)
              ++ map mylib.relativeToRoot [
                "modules/nixos_headless/traffic-quota.nix"
                "modules/services/traefik.nix"
                "modules/services/prometheus-exporters.nix"
              ]
              ++ [ ./_common ];
            hmModules = features.hm.common.base;
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
    name: nixos_cfg: mylib.genDeployNode nixos_cfg.config.vars.hostAddrs.${name} nixos_cfg
  ) nixos_configurations;
}

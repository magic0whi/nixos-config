{
  machineConfigs,
  mylib,
  const,
  features,
  nixpkgs,
  ...
}:
groupDir:
let
  names = map (p: baseNameOf p) (mylib.scanPath groupDir);
  nixos_configurations =
    let
      gen_nixos_system =
        name:
        nixpkgs.lib.nixosSystem (
          mylib.mkOsConfiguration {
            inherit
              name
              mylib
              const
              machineConfigs
              ;
            machinePath = groupDir + "/${name}";
            overlays = with features; common.baseOverlays;
            modules =
              (with features; common.base ++ common.services ++ nixos.base)
              ++ map mylib.relativeToRoot [
                "modules/nixos_headless/traffic-quota.nix"
                "modules/services/traefik.nix"
                "modules/services/prometheus-exporters.nix"
                "modules/services/garage.nix"
              ]
              ++ [
                ./common
                (groupDir + "/_common") # Per-provider overrides (e.g. root partition layout)
              ];
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
    name: nixosCfg:
    mylib.mkDeployNode {
      nics = nixosCfg.config.vars.hostAddrs.${name};
      inherit nixosCfg;
    }
  ) nixos_configurations;
}

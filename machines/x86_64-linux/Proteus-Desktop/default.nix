{
  machineConfigs,
  mylib,
  myvars,
  nixpkgs,
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
        myvars
        ;
      machinePath = ./.;
      nixpkgsModules =
        myvars.base.nixpkgsModules
        ++ (map mylib.relativeToRoot [
          "modules/common/sing-box-client.nix"

          "modules/nixos_headless/krnl-compat.nix"
          "modules/nixos_headless/packages.nix"
          "modules/nixos_headless/zfs.nix"

          "modules/nixos_gui/kmscon.nix"

          "modules/services/docker.nix"
          "modules/services/traefik.nix"
        ]);
      hmModules = map mylib.relativeToRoot [
        "modules/common_hm_headless/helix.nix"
        "modules/common_hm_headless/misc.nix"
        "modules/common_hm_headless/nix.nix"
        "modules/common_hm_headless/shell.nix"
      ];
    }
  );
in
{
  _DEBUG = { inherit name; };
  nixos_configurations.${name} = nixos_system;
  deploy-rs_nodes.${name} = mylib.genDeployNode myvars.networking.hostAddrs.${name} nixos_system;
}

{
  lib,
  self,
  inputs,
  mylib,
  ...
}:
let
  ## BEGIN Functions
  # The args given to machines
  gen_machine_args =
    system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    inputs
    // {
      inherit lib system;

      const = import ./const {
        inherit
          pkgs
          mylib
          lib
          ;
        inherit (self) nixosConfigurations;
      };
      mylib =
        let
          mylib_pkg_funcs = mylib.mkForPkgs pkgs;
        in
        mylib
        // mylib_pkg_funcs
        // {
          genOsConfiguration = mylib_pkg_funcs.genOsConfiguration_unwrapped inputs.home-manager;
          genDeployNode = mylib.genDeployNode_unwrapped inputs.deploy-rs.lib;
        };

      features = import ./machines/feature-levels.nix { inherit mylib inputs; };

      machineConfigs = with self; nixosConfigurations // darwinConfigurations;
    };
  import_each_system =
    supported_systems:
    lib.genAttrs supported_systems (
      system: import ./machines system { inherit lib mylib; } ((gen_machine_args system) // { inherit inputs; })
    );
  ## END Functions

  ## BEGIN Variables
  nixos_machines = import_each_system [
    "x86_64-linux"
    # "aarch64-linux"
    "riscv64-linux"
  ];
  darwin_machines = import_each_system [ "aarch64-darwin" ];
  nixos_machines_values = builtins.attrValues nixos_machines;
  darwin_machines_values = builtins.attrValues darwin_machines;
  ## END Variables
in
{
  # Merge all the machines into a single attribute set (Multi-arch)
  flake = {
    nixosConfigurations = lib.mergeAttrsList (map (system: system.nixos_configurations or { }) nixos_machines_values);
    darwinConfigurations = lib.mergeAttrsList (map (system: system.darwin_configurations or { }) darwin_machines_values);
    deploy = {
      interactiveSudo = true;
      fastConnection = true;
      nodes =
        let
          machine_blacklist = [ "Proteus-VF2" ];
        in
        lib.filterAttrs (name: _: !builtins.elem name machine_blacklist) (
          lib.mergeAttrsList (map (i: i.deploy_nodes or { }) nixos_machines_values)
        );
    };
  };
  perSystem =
    { system, ... }:
    {
      # DEBUG: Add attribute sets into allSystems/currentSystem for debugging
      debug = {
        inherit
          inputs
          nixos_machines
          darwin_machines
          ;
        args = gen_machine_args system;
      };
      packages = nixos_machines.${system}.packages or { };
      # Currently deploy-rs check broken on MacOS/riscv64-linux
      checks = lib.optionalAttrs (system != "riscv64-linux" && (system != "aarch64-darwin")) (
        inputs.deploy-rs.lib.${system}.deployChecks self.deploy
      );
    };
}

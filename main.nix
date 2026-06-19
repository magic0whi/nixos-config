{
  lib,
  self,
  inputs,
  ...
}:
let
  mylib = import ./libs lib;
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

      const = import ./const { inherit lib pkgs mylib; };
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
  nixos_systems = import_each_system [
    "x86_64-linux"
    # "aarch64-linux"
    "riscv64-linux"
  ];
  darwin_systems = import_each_system [ "aarch64-darwin" ];
  nixos_systems_values = builtins.attrValues nixos_systems;
  darwin_systems_values = builtins.attrValues darwin_systems;
  ## END Variables
in
{
  # Merge all the machines into a single attribute set (Multi-arch)
  flake = {
    nixosConfigurations = lib.mergeAttrsList (map (i: i.nixos_configurations or { }) nixos_systems_values);
    darwinConfigurations = lib.mergeAttrsList (map (i: i.darwin_configurations or { }) darwin_systems_values);
    deploy = {
      interactiveSudo = true;
      fastConnection = true;
      nodes =
        let
          machine_blacklist = [ "Proteus-VF2" ];
        in
        lib.filterAttrs (name: _: !builtins.elem name machine_blacklist) (
          lib.mergeAttrsList (map (i: i.deploy_nodes or { }) nixos_systems_values)
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
          nixos_systems
          darwin_systems
          ;
        args = gen_machine_args system;
      };
      packages = nixos_systems.${system}.packages or { };
      # Currently deploy-rs check broken on MacOS/riscv64-linux
      checks =
        if (system != "riscv64-linux") && (system != "aarch64-darwin") then
          (inputs.deploy-rs.lib.${system}.deployChecks self.deploy)
        else
          { };
    };
}

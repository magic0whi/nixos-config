{
  lib,
  self,
  inputs,
  ...
}:
let
  # inherit (inputs.nixpkgs) lib;
  ## BEGIN Functions
  gen_args =
    system:
    let
      mylib = import ./libs { inherit inputs; };
      myvars = import ./vars { inherit lib mylib; };
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    {
      # The args given to other nix files
      inherit lib system;
      inherit (inputs) nix-darwin nixpkgs nixos-hardware;
      myvars = lib.recursiveUpdate (myvars // myvars.mkForPkgs pkgs) {
        networking.findHost = with myvars.networking; _find_host hostAddrs;
      };
      mylib = mylib // (mylib.mkForPkgs pkgs);
      machineConfigs = with self; nixosConfigurations // darwinConfigurations;
    };
  import_each_system = supported_systems: lib.genAttrs supported_systems (system: import ./machines (gen_args system));
  ## END Functions

  ## BEGIN Variables
  nixos_systems = import_each_system [
    "x86_64-linux"
    # "aarch64-linux"
    "riscv64-linux" # Disable temporary, NOTE: Remove derivations that has GHC dependency
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
      nodes = lib.mergeAttrsList (map (i: i.deploy-rs_nodes or { }) nixos_systems_values);
    };
  };
  perSystem =
    { system, ... }:
    {
      # DEBUG: Add attribute sets into allSystems/currentSystem for debugging
      debug = {
        inherit
          inputs
          gen_args
          nixos_systems
          darwin_systems
          ;
      };
      packages = nixos_systems.${system}.packages or { };
      checks = (inputs.deploy-rs.lib.${system}.deployChecks self.deploy); # Currently deploy-rs check broken on MacOS
    };
}

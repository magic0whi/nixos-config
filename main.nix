{
  self,
  inputs,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;
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
      inherit (inputs) nix-darwin;
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
  ];
  darwin_systems = import_each_system [
    # "x86_64-darwin"
    "aarch64-darwin"
  ];
  nixos_systems_values = builtins.attrValues nixos_systems;
  darwin_systems_values = builtins.attrValues darwin_systems;
  ## END Variables
in
{
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
    # "riscv64-linux" # Disable temporary, NOTE: Remove closures that has GHC dependency
  ];
  # Merge all the machines into a single attribute set (Multi-arch)
  flake = {
    # DEBUG: Add attribute sets into outputs for debugging
    _DEBUG = {
      inherit
        inputs
        gen_args
        nixos_systems
        darwin_systems
        ;
    };
    nixosConfigurations = lib.mergeAttrsList (map (i: i.nixos_configurations or { }) nixos_systems_values);
    darwinConfigurations = lib.mergeAttrsList (map (i: i.darwin_configurations or { }) darwin_systems_values);
    deploy = {
      interactiveSudo = true;
      fastConnection = true;
      nodes = lib.mergeAttrsList (map (i: i.deploy-rs_nodes or { }) nixos_systems_values);
    };
    checks = builtins.mapAttrs (_: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
  };

  perSystem =
    { pkgs, system, ... }:
    {
      packages = nixos_systems.${system}.packages or { };
      # Currently deploy_checks broken on MacOS
      checks = lib.mkMerge [
        {
          # TIP: `nix build .#checks.x86_64-linux.mylib_tests`
          mylib_tests =
            let
              result = pkgs.callPackage ./libs/tests.nix { inherit inputs; };
            in
            if result == [ ] then
              pkgs.runCommand "lib-tests-passed" { } ''
                echo "All custom library unit tests passed on ${pkgs.stdenv.hostPlatform.system}!"
                touch $out
              ''
            else
              throw ''
                Library unit tests failed on ${pkgs.stdenv.hostPlatform.system}!
                ${builtins.toJSON result}
              '';
        }
        (lib.mkIf (!pkgs.stdenv.isDarwin) { vm_tests = import ./tests { inherit pkgs; }; })
      ];
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixfmt-rs
          prettier
        ];
        name = "nixos-config";
      };
    };
}

{
  deploy-rs,
  nix-darwin,
  nixpkgs,
  self,
  treefmt-nix,
  ...
}@inputs:
let
  inherit (inputs.nixpkgs) lib;
  ## BEGIN Functions
  for_each_system =
    f: lib.genAttrs (builtins.attrNames (nixos_systems // darwin_systems)) (system: f nixpkgs.legacyPackages.${system});

  treefmt_eval = for_each_system (pkgs: treefmt-nix.lib.evalModule pkgs (import ./treefmt.nix pkgs));

  gen_args =
    let
      mylib = import ./libs { inherit inputs; };
      myvars = import ./vars { inherit lib mylib; };
    in
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # The args given to other nix files
      inherit lib system nix-darwin;
      myvars = lib.recursiveUpdate (myvars // myvars.mkForPkgs pkgs) {
        networking.find_host = with myvars.networking; _find_host hosts_addr;
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
    # "riscv64-linux" # Disable temporary, NOTE: Remove closures that has GHC dependency
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
  # DEBUG: Add attribute sets into outputs for debugging
  _DEBUG = {
    inherit
      inputs
      gen_args
      nixos_systems
      darwin_systems
      ;
  };
  # Merge all the machines into a single attribute set (Multi-arch)
  nixosConfigurations = lib.mergeAttrsList (map (i: i.nixos_configurations or { }) nixos_systems_values);
  # Packages: iso images, TODO, derive ISO from a machine's config is a bad idea
  packages = lib.genAttrs (builtins.attrNames nixos_systems) (system: nixos_systems.${system}.packages or { });
  darwinConfigurations = lib.mergeAttrsList (map (i: i.darwin_configurations or { }) darwin_systems_values);
  deploy = {
    interactiveSudo = true;
    fastConnection = true;
    nodes = lib.mergeAttrsList (map (i: i.deploy-rs_nodes or { }) nixos_systems_values);
  };
  # Currently deploy_checks broken on MacOS
  checks =
    let
      deploy_checks = builtins.mapAttrs (_: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      my_checks = for_each_system (
        pkgs:
        let
          lib_test_results = pkgs.callPackage ./libs/tests.nix { inherit inputs; };
          vm_tests = import ./tests { inherit pkgs; };
        in
        {
          # TIP: `nix build .#checks.x86_64-linux.mylib_tests`
          mylib_tests =
            if lib_test_results == [ ] then
              pkgs.runCommand "lib-tests-passed" { } ''
                echo "All custom library unit tests passed on ${pkgs.stdenv.hostPlatform.system}!"
                touch $out
              ''
            else
              throw ''
                Library unit tests failed on ${pkgs.stdenv.hostPlatform.system}!
                ${builtins.toJSON lib_test_results}
              '';

          format_check = treefmt_eval.${pkgs.stdenv.hostPlatform.system}.config.build.check self;
        }
        // lib.optionalAttrs (!pkgs.stdenv.isDarwin) vm_tests
      );
    in
    lib.recursiveUpdate deploy_checks my_checks;

  formatter = for_each_system (pkgs: treefmt_eval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper);

  devShells = for_each_system (pkgs: {
    default = pkgs.mkShell {
      buildInputs = [ pkgs.nixfmt-rs ];
      name = "nixos-config";
    };
  });
}

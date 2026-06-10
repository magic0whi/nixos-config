{
  # deploy-rs,
  mylib,
  myvars,
  nix-darwin,
  # system,
  ...
}:
let
  name = baseNameOf ./.;
  darwin_system = nix-darwin.lib.darwinSystem (
    mylib.genOsConfiguration {
      inherit
        name
        mylib
        myvars
        ;
      machinePath = ./.;
      nixpkgsModules = map mylib.relativeToRoot [
        "modules/common"
        "modules/darwin"
      ];
      hmModules = map mylib.relativeToRoot [
        "modules/common_hm_headless"
        "modules/common_hm_gui"
        "modules/darwin_hm"
      ];
    }
  );
in
{
  _DEBUG = { inherit name; };
  darwin_configurations.${name} = darwin_system;
  # It’s only possible to cross compile between aarch64-darwin and x86_64-darwin
  # Ref: https://nix.dev/tutorials/cross-compilation.html#determining-the-host-platform-config
  # deploy-rs_nodes.${name} = {
  #   ...
  #   profiles.system = {
  #     path = deploy-rs.lib.${system}.activate.darwin darwin_system;
  #     ...
  #   };
  # };
}

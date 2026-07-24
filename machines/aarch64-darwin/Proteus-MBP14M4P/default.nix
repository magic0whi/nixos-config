{
  mylib,
  const,
  machineConfigs,
  features,
  nix-darwin,
  deploy-rs,
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
        const
        machineConfigs
        ;
      overlays = with features; common.baseOverlays;
      machinePath = ./.;
      specialArgs = { inherit deploy-rs; };
      modules = (with features.common; base ++ seat ++ extra) ++ features.darwin;
      hmModules = (with features.hm.common; base ++ seat) ++ features.hm.darwin;
    }
  );
in
{
  _DEBUG = { inherit name; };
  darwin_configurations.${name} = darwin_system;
  # It’s only possible to cross compile between aarch64-darwin and x86_64-darwin
  # Ref: https://nix.dev/tutorials/cross-compilation.html#determining-the-host-platform-config
  deploy_nodes.${name} = mylib.genDeployNode {
    nics = darwin_system.config.vars.hostAddrs.${name};
    nixosCfg = darwin_system;
  };
  # deploy_nodes.${name} = {
  #   ...
  #   profiles.system = {
  #     path = deploy-rs.lib.${system}.activate.darwin darwin_system;
  #     ...
  #   };
  # };
}

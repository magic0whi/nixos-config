{
  machineConfigs,
  mylib,
  mypkg,
  const,
  features,

  niks3,
  nixpkgs,
  dns,
  ...
}:
let
  name = baseNameOf ./.;
  nixosCfg = nixpkgs.lib.nixosSystem (
    mylib.mkOsConfiguration {
      inherit
        name
        machineConfigs
        mylib
        mypkg
        const
        ;
      machinePath = ./.;
      specialArgs = { inherit dns; };
      overlays = (with features; common.baseOverlays);
      modules =
        (with features.common; base)
        ++ (with features.nixos; base)
        ++ [ niks3.nixosModules.niks3 ]
        ++ (map mylib.relToRoot (
          let
            common = "modules/common";
            headless = "modules/nixos_headless";
            services = "modules/services";
          in
          [
            "${common}/sing-box-client.nix"
            "${common}/fonts.nix"
            "${common}/packages.nix"

            "${headless}/firewall-client.nix"
            "${headless}/krnl-compat.nix"
            "${headless}/packages.nix"
            "${headless}/scx-loader.nix"
            "${headless}/zfs.nix"

            "modules/nixos_gui/kmscon.nix"

            "${services}/authelia-online.nix"
            "${services}/darknet.nix"
            "${services}/docker.nix"
            "${services}/garage.nix"
            "${services}/ldap-online.nix"
            "${services}/prometheus-exporters.nix"
            "${services}/restic.nix"
            "${services}/traefik.nix"
          ]
        ));
      hmModules = features.hm.common.base;
    }
  );
in
{
  _DEBUG = { inherit name; };
  nixos_configurations.${name} = nixosCfg;
  deploy_nodes.${name} = mylib.mkDeployNode {
    nics = nixosCfg.config.vars.hostAddrs.${name};
    inherit nixosCfg;
  };
}

{
  machineConfigs,
  mylib,
  mypkg,
  const,
  features,

  NixVirt,
  agent-skills,
  deploy-rs,
  dev-flake,
  i915-sriov-dkms,
  nixpkgs,
  nixvim,
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
        ;
      machinePath = ./.;
      const = const // {
        igpu_sym_name = "intel";
        # `lspci -Dnnd 8086::03xx | cut -f1 -d' '`
        igpu_pci_ids = "0000:00:02.0";
        dgpu_sym_name = "nvidia";
        # `lspci -Dnnd 10de::03xx | cut -f1 -d' '`
        dgpu_pci_ids = "0000:01:00.0";
      };
      overlays = with features; common.baseOverlays ++ nixos.seat.guiOverlays;
      specialArgs = {
        inherit
          NixVirt
          agent-skills
          deploy-rs
          dev-flake
          nixvim
          ;
      };
      modules =
        (with features.common; base ++ seat)
        ++ (with features.nixos; base ++ seat.tui ++ seat.gui)
        ++ [
          i915-sriov-dkms.nixosModules.default
          NixVirt.nixosModules.default
        ]
        ++ map mylib.relToRoot (
          let
            services = "modules/services";
          in
          [
            "modules/nixos_headless/iwd.nix"

            "${services}/darknet.nix"
            "${services}/docker.nix"
            "${services}/prometheus-exporters.nix"
            "${services}/restic.nix"
            "${services}/traefik.nix"
          ]
        );

      hmModules = (with features.hm.common; base ++ seat) ++ features.hm.nixos;
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

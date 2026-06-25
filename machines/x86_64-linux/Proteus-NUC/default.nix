{
  machineConfigs,
  mylib,
  const,
  features,

  deploy-rs,
  nixpkgs,
  i915-sriov-dkms,
  ...
}:
let
  name = baseNameOf ./.;
  nixos_cfg = nixpkgs.lib.nixosSystem (
    mylib.genOsConfiguration {
      inherit
        name
        machineConfigs
        mylib
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
      specialArgs = { inherit deploy-rs; };
      modules =
        (with features.common; base ++ seat ++ extra)
        ++ (with features.nixos; base ++ seat.tui ++ seat.gui ++ extra)
        ++ [ i915-sriov-dkms.nixosModules.default ]
        ++ map mylib.relativeToRoot [
          "modules/nixos_headless/iwd.nix"
          "modules/services/traefik.nix"
          "modules/services/docker.nix"
        ];

      hmModules = (with features.hm.common; base ++ seat) ++ features.hm.nixos;
    }
  );
in
{
  _DEBUG = { inherit name features; };
  nixos_configurations.${name} = nixos_cfg;
  deploy_nodes.${name} = mylib.genDeployNode nixos_cfg.config.vars.hostAddrs.${name} nixos_cfg;
}

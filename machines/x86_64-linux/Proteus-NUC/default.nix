{
  machineConfigs,
  mylib,
  myvars,
  nixpkgs,
  ...
}:
let
  name = baseNameOf ./.;
  nixos_system = nixpkgs.lib.nixosSystem (
    mylib.genOsConfiguration {
      inherit
        name
        machineConfigs
        mylib
        ;
      machinePath = ./.;
      myvars = myvars // {
        igpu_sym_name = "intel";
        # `lspci -Dnnd 8086::03xx | cut -f1 -d' '`
        igpu_pci_ids = "0000:00:02.0";
        dgpu_sym_name = "nvidia";
        # `lspci -Dnnd 10de::03xx | cut -f1 -d' '`
        dgpu_pci_ids = "0000:01:00.0";
      };
      nixpkgsModules = map mylib.relativeToRoot [
        "modules/overlays"

        # "modules/common/default.nix"
        "modules/common/easytier.nix"
        "modules/common/fonts.nix"
        "modules/common/misc.nix"
        "modules/common/nix.nix"
        "modules/common/packages.nix"
        "modules/common/secrets.nix"
        "modules/common/shell.nix"
        "modules/common/ssh.nix"
        # "modules/common/tailscale.nix"

        "modules/nixos_headless"

        "modules/nixos_gui"

        "modules/services/traefik.nix"
        "modules/services/docker.nix"
      ];
      hmModules = map mylib.relativeToRoot [
        "modules/common_hm_headless"

        "modules/common_hm_gui"

        "modules/nixos_hm_headless"

        "modules/nixos_hm_gui"
      ];
    }
  );
in
{
  _DEBUG = { inherit name; };
  nixos_configurations.${name} = nixos_system;
  # packages.${name} = nixos_iso; # generate iso image
  deploy-rs_nodes.${name} = mylib.genDeployNode myvars.networking.hostAddrs.${name} nixos_system;
}

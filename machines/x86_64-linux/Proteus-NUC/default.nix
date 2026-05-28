{
  lib,
  mylib,
  myvars,
  ...
}:
let
  name = baseNameOf ./.;
  nixpkgs_modules = map mylib.relative_to_root [
    "modules/secrets"

    "modules/overlays"

    "modules/common"

    "modules/nixos_headless"

    "modules/nixos_gui"

    "modules/services/traefik.nix"
  ];
  hm_modules = map mylib.relative_to_root [
    "modules/common_hm_headless"

    "modules/common_hm_gui"

    "modules/nixos_hm_headless"

    "modules/nixos_hm_gui"
  ];
  nuc_myvars = myvars // {
    igpu_sym_name = "intel";
    # `lspci -Dnnd 8086::03xx | cut -f1 -d' '`
    igpu_pci_ids = "0000:00:02.0";
    dgpu_sym_name = "nvidia";
    # `lspci -Dnnd 10de::03xx | cut -f1 -d' '`
    dgpu_pci_ids = "0000:01:00.0";
  };
  nixos_system = lib.nixosSystem (
    mylib.gen_system_args {
      inherit
        name
        mylib
        nixpkgs_modules
        hm_modules
        ;
      myvars = nuc_myvars;
      machine_path = ./.;
    }
  );
  # nixos_iso =
  #   (lib.nixosSystem (
  #     mylib.gen_system_args {
  #       inherit
  #         name
  #         mylib
  #         nixpkgs_modules
  #         hm_modules
  #         ;
  #       generate_iso = true;
  #       myvars = nuc_myvars;
  #       machine_path = ./.;
  #     }
  #   )).config.system.build.images.iso;
in
{
  _DEBUG = {
    inherit
      name
      nixpkgs_modules
      hm_modules
      myvars
      mylib
      nixos_system
      ;
  };
  nixos_configurations.${name} = nixos_system;
  # packages.${name} = nixos_iso; # generate iso image
  deploy-rs_node.${name} = mylib.gen_deploy-rs_node myvars.networking.hosts_addr.${name} nixos_system;
}

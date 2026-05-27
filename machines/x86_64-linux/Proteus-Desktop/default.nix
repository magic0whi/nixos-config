{
  lib,
  mylib,
  myvars,
  ...
}:
let
  name = baseNameOf ./.;
  nixpkgs_modules =
    myvars.base.nixpkgs_modules
    ++ (map mylib.relative_to_root [
      "modules/nixos_headless/packages.nix"
      "modules/nixos_headless/services_traefik.nix"
      "modules/nixos_headless/zfs.nix"

      "modules/nixos_gui/kmscon.nix"
    ]);
  hm_modules = map mylib.relative_to_root [
    "modules/common_hm_headless/misc.nix"
    "modules/common_hm_headless/shell.nix"
  ];
  desktop_myvars = myvars;
  nixos_system = lib.nixosSystem (
    mylib.gen_system_args {
      inherit
        name
        mylib
        nixpkgs_modules
        hm_modules
        ;
      myvars = desktop_myvars;
      machine_path = ./.;
    }
  );
  nixos_iso =
    (lib.nixosSystem (
      mylib.gen_system_args {
        inherit
          name
          mylib
          nixpkgs_modules
          hm_modules
          ;
        myvars = desktop_myvars;
        generate_iso = true;
        machine_path = ./.;
      }
    )).config.system.build.images.iso;
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
  packages.${name} = nixos_iso; # generate iso image
  deploy-rs_node.${name} = mylib.gen_deploy-rs_node myvars.networking.hosts_addr.${name} nixos_system;
}

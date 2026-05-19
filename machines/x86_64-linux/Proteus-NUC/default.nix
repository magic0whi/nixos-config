{
  deploy-rs,
  lib,
  mylib,
  myvars,
  system,
  ...
}: let
  name = baseNameOf ./.;
  nixpkgs_modules = map mylib.relative_to_root [
    "modules/secrets/common.nix"
    "modules/overlays"
    "modules/common"
    "modules/nixos_headless"
    "modules/nixos_headless/_impermanence.nix"
    "modules/nixos_gui"
  ];
  hm_modules = map mylib.relative_to_root [
    "modules/common_hm_headless"
    "modules/common_hm_gui"
    "modules/nixos_hm_headless"
    "modules/nixos_hm_gui"
  ];
  nuc_myvars =
    myvars
    // {
      igpu_sym_name = "intel";
      # `lspci -Dnnd 8086::03xx | cut -f1 -d' '`
      igpu_pci_ids = "0000:00:02.0";
      dgpu_sym_name = "nvidia";
      # `lspci -Dnnd 10de::03xx | cut -f1 -d' '`
      dgpu_pci_ids = "0000:01:00.0";
    };
  nixos_system = lib.nixosSystem (mylib.gen_system_args {
    inherit name mylib nixpkgs_modules hm_modules;
    myvars = nuc_myvars;
    machine_path = ./.;
  });
  nixos_iso =
    (lib.nixosSystem (mylib.gen_system_args {
      inherit name mylib nixpkgs_modules hm_modules;
      generate_iso = true;
      myvars = nuc_myvars;
      machine_path = ./.;
    })).config.system.build.images.iso;
in {
  _DEBUG = {inherit name nixpkgs_modules hm_modules myvars mylib;};
  nixos_configurations.${name} = nixos_system;
  # generate iso image
  # packages.${name} = inputs.self.nixosConfigurations.${name}.config.formats.iso;
  packages.${name} = nixos_iso;
  deploy-rs_node.${name} = {
    hostname = let
      ifaces = myvars.networking.hosts_addr.${name};
      ts_iface = builtins.elemAt ifaces 0;
      et_iface = lib.optionalAttrs (builtins.length ifaces >= 2) (builtins.elemAt ifaces 1);
    in
      if et_iface ? ipv4
      then et_iface.ipv4
      else if ts_iface ? ipv4
      then ts_iface.ipv4
      else name;
    sshUser = "root";
    interactiveSudo = false; # Since we use 'root' user to ssh
    profiles.system = {
      path = deploy-rs.lib.${system}.activate.nixos nixos_system;
      user = "root";
    };
  };
}

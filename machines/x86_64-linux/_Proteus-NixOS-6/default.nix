{
  inputs,
  mylib,
  myvars,
  system,
  ...
}: let
  name = baseNameOf ./.;
  nixpkgs_modules = map mylib.relative_to_root [
    "modules/secrets/common.nix"
    "modules/common"
    "modules/nixos_headless/_impermanence.nix"
    "modules/nixos_headless/misc.nix"
    "modules/nixos_headless/packages.nix"
    "modules/nixos_headless/sing-box.nix"
  ];
  hm_modules = map mylib.relative_to_root [
    "modules/common_hm_headless/git.nix"
    "modules/common_hm_headless/helix.nix"
    "modules/common_hm_headless/shell.nix"
    "modules/common_hm_headless/misc.nix"
    "modules/nixos_hm_headless/shell.nix"
  ];
  nixos_system = inputs.nixpkgs.lib.nixosSystem (mylib.gen_system_args {
    inherit name mylib myvars nixpkgs_modules hm_modules;
    machine_path = ./.;
  });
in {
  _DEBUG = {inherit name nixpkgs_modules hm_modules myvars mylib;};
  nixos_configurations.${name} = nixos_system;
  deploy-rs_node.${name} = {
    hostname = let
      ifaces = myvars.networking.hosts_addr.${name};
      ts_iface = builtins.elemAt ifaces 0;
      et_iface = builtins.elemAt ifaces 1;
    in
      if ((builtins.length ifaces) >= 2 && et_iface ? ipv4)
      then et_iface.ipv4
      else if (ts_iface ? ipv4)
      then ts_iface.ipv4
      else name;
    sshUser = "root";
    interactiveSudo = false; # Since we use 'root' user to ssh
    profiles.system = {
      path = inputs.deploy-rs.lib.${system}.activate.nixos nixos_system;
      user = "root";
    };
  };
}

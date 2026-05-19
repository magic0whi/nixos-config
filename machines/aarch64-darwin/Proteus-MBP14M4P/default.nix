{
  # deploy-rs,
  mylib,
  myvars,
  nix-darwin,
  # system,
  ...
}: let
  name = baseNameOf ./.;
  nixpkgs_modules = map mylib.relative_to_root [
    "modules/secrets"
    "modules/common"
    "modules/darwin"
  ];
  hm_modules = map mylib.relative_to_root [
    "modules/common_hm_headless"
    "modules/common_hm_gui"
    "modules/darwin_hm"
  ];
  darwin_system = nix-darwin.lib.darwinSystem (mylib.gen_system_args {
    inherit name mylib myvars nixpkgs_modules hm_modules;
    machine_path = ./.;
  });
in {
  _DEBUG = {inherit name nixpkgs_modules hm_modules;};
  darwin_configurations.${name} = darwin_system;
  # It’s only possible to cross compile between aarch64-darwin and x86_64-darwin
  # Ref: https://nix.dev/tutorials/cross-compilation.html#determining-the-host-platform-config
  # deploy-rs_node.${name} = {
  #   hostname = let
  #     ifaces = myvars.networking.hosts_addr.${name};
  #     ts_iface = builtins.elemAt ifaces 0;
  #     et_iface = lib.optionalAttrs (builtins.length ifaces >= 2) (builtins.elemAt ifaces 1);
  #   in
  #     if et_iface ? ipv4
  #     then et_iface.ipv4
  #     else if ts_iface ? ipv4
  #     then ts_iface.ipv4
  #     else name;
  #   profiles.system = {
  #     path = deploy-rs.lib.${system}.activate.darwin darwin_system;
  #     user = "root";
  #   };
  # };
}

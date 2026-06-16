system: # Imported subdir
{ lib, mylib }:
machine_args:
let
  # machines topology:
  # machines = {
  #   GCP = {
  #     _DEBUG = {...};
  #     nixos_configurations = {
  #       Proteus-NixOS-0 = {...};
  #       Proteus-NixOS-1 = {...};
  #       ...
  #     };
  #     packages = {
  #       Proteus-NixOS-0 = {...};
  #       Proteus-NixOS-1 = {...};
  #       ...
  #     };
  #     deploy_nodes = {
  #       Proteus-NixOS-0 = {...};
  #       Proteus-NixOS-1 = {...};
  #       ...
  #     };
  #   }
  #   Proteus-NUC = {
  #     _DEBUG = {...};
  #     nixos_configurations.Proteus-NUC = {...};
  #     deploy_nodes.Proteus-NUC = {...};
  #   };
  # }
  machines = builtins.foldl' (
    acc: machine_dir: acc // { ${baseNameOf machine_dir} = import machine_dir machine_args; }
  ) { } (mylib.scanPath ./${system});

  flatten_attrs =
    attr:
    lib.foldlAttrs (
      acc: _: nixos_cfg:
      acc // (nixos_cfg.${attr} or { })
    ) { };
in
{
  _DEBUG = { inherit machines; };
  nixos_configurations = flatten_attrs "nixos_configurations" machines;
  darwin_configurations = flatten_attrs "darwin_configurations" machines;
  packages = flatten_attrs "packages" machines;
  deploy_nodes = flatten_attrs "deploy_nodes" machines;
}

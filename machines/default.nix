{
  lib,
  mylib,
  system,
  ...
}@args:
let
  machines = builtins.foldl' (acc: machine: lib.recursiveUpdate acc (import machine args)) { } (
    mylib.scanPath ./${system}
  );
in
{
  _DEBUG = { inherit machines; }; # TIP: Use 'builtins.elemAt lists index' to keep lazy eval
  # Merge all the same arch machines into a single attribute set
  inherit (machines) nixos_configurations;
  # nixos_configurations = lib.mergeAttrsList (map (i: i.nixos_configurations or { }) machines);
  darwin_configurations = machines.darwin_configurations or { };
  packages = machines.packages or { };
  deploy-rs_nodes = machines.deploy-rs_nodes or { };
}

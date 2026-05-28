{
  lib,
  mylib,
  system,
  ...
}@args:
let
  machines = map (i: import i args) (mylib.scanPath ./${system});
in
{
  _DEBUG = { inherit machines; }; # TIP: Use 'builtins.elemAt lists index' to keep lazy eval
  # Merge all the same arch machines into a single attribute set
  nixos_configurations = lib.mergeAttrsList (map (i: i.nixos_configurations or { }) machines);
  darwin_configurations = lib.mergeAttrsList (map (i: i.darwin_configurations or { }) machines);
  packages = lib.mergeAttrsList (map (i: i.packages or { }) machines);
  deploy-rs_nodes = lib.mergeAttrsList (map (i: i.deploy-rs_node or { }) machines);
}

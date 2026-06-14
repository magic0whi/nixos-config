{ config, lib, ... }:
let
  cfg = config.debug;
in
{
  options.debug = lib.mkOption {
    # Accepts literally any Nix value (functions, derivations, attrsets, etc.)
    type = lib.types.raw; # or lib.types.anything
    default = null;
    description = "Any value for debugging";
  };
  config = lib.mkIf (cfg != null) {
    warnings = [
      ''
        NixOS: `debug` is set to a non-null value. This is intended for temporary debugging only and should be removed
        before committing.
      ''
    ];
  };
}

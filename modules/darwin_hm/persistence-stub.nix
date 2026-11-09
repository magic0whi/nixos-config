# No-op stand-in for impermanence's `home.persistence`, which only exists when the NixOS impermanence module injects it.
{ lib, ... }:
{
  options.home.persistence = lib.mkOption {
    type =
      with lib.types;
      attrsOf (submodule {
        freeformType = attrsOf unspecified;
        options = {
          directories = lib.mkOption {
            type = listOf anything;
            default = [ ];
          };
          files = lib.mkOption {
            type = listOf anything;
            default = [ ];
          };
        };
      });
    default = { };
    description = "Ignored on darwin.";
  };
}

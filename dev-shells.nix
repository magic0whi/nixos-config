_: {
  perSystem =
    { config, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        buildInputs = [ config.treefmt.build.wrapper ] ++ builtins.attrValues config.treefmt.build.programs;
        name = "nixos-config";
      };
    };
}

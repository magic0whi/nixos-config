{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.lix-module.overlays.default ];
        config.allowUnfree = true;
      };
    };
}

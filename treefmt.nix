{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];
  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix"; # Used to find the project root
        programs.nixfmt = {
          enable = true;
          width =
            (import ./const/default.nix {
              lib = null;
              pkgs = null;
              mylib = null;
              nixosConfigurations = null;
              darwinConfigurations = null;
            }).lineWidth;
          package = pkgs.nixfmt-rs;
          priority = 0;
        };
        programs.deadnix = {
          enable = true;
          priority = 1;
        };
        programs.nixf-diagnose = {
          enable = true;
          priority = 2;
        };
        programs.prettier = {
          enable = true;
          # package = pkgs.prettier.override { plugins = [ ... ]; };
        };
        programs.just.enable = true;
        programs.shfmt.enable = true;
      };
    };
}

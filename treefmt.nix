pkgs: {
  projectRootFile = "flake.nix"; # Used to find the project root
  programs.nixfmt = {
    enable = true;
    width = 120;
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
  programs.prettier.enable = true;
  programs.just.enable = true;
  programs.shfmt.enable = true;
}

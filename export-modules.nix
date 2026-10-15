{
  flake = {
    # TIP: If file utilize custom functions, use
    # lib.modules.importApply ./modules/to/export.nix { mylib = ...; };
    nixosModules.traffix-quota = ./modules/nixos_headless/traffic-quota.nix;
    homeModules.niri = ./modules/nixos_hm_gui/niri/niri.nix;
  };
}

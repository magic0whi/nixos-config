{pkgs}: {
  # TIP:
  # - To enter interactive environment, run `nix run .#checks.x86_64-linux.bind.driverInteractive`
  # - To get a shell, either use `interactive.sshBackdoor.enable = true;` or `<machine_name>.shell_interact()` from the
  #   Python REPL

  traffic-quota = pkgs.callPackage ./traffic-quota.nix {};
  bind = pkgs.callPackage ./bind.nix {};

  # nix-darwin does not have a VM testing framework
  # easytier = pkgs.callPackage ./easytier.nix {};
}

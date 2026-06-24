{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Cross compilation
  boot.binfmt.emulatedSystems = [
    "riscv64-linux"
    "aarch64-linux"
  ];
  # For riscv64 docker container
  boot.binfmt.registrations = lib.mkIf config.virtualisation.docker.enable {
    "riscv64-linux" = {
      interpreter = "${lib.getExe' pkgs.pkgsStatic.qemu-user "qemu-riscv64"}";
      fixBinary = true;
      wrapInterpreterInShell = false;
    };
  };
}

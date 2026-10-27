{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.binfmt = {
    # Cross compilation
    emulatedSystems = [
      "riscv64-linux"
      "aarch64-linux"
    ];

    # For riscv64 docker container
    registrations = lib.mkIf config.virtualisation.docker.enable {
      riscv64-linux = {
        interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-riscv64";
        fixBinary = true;
        wrapInterpreterInShell = false;
      };
    };
  };
}

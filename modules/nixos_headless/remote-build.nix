{myvars, ...}: {
  # NixOS's Configuration for Remote Building / Distributed Building
  #
  # Related Docs:
  #   1. https://github.com/NixOS/nix/issues/7380
  #   2. https://nixos.wiki/wiki/Distributed_build
  #   3. https://github.com/NixOS/nix/issues/2589
  #
  ####################################################################

  # set local's max-job to 0 to force remote building (disable local building)
  # nix.settings.max-jobs = 0;
  nix.distributedBuilds = true;
  nix.buildMachines = let
    sshUser = myvars.username;
    # ssh key's path on local machine
    # sshKey = "/srv/sync_work/3keys/pgp2ssh.priv.key";
    systems = [
      # Native arch
      "x86_64-linux"
      # Emulated arch using binfmt_misc and qemu-user
      "aarch64-linux"
      "riscv64-linux"
    ];
    # all available system features are poorly documentd here:
    # https://github.com/NixOS/nix/blob/e503ead/src/libstore/globals.hh#L673-L687
    supportedFeatures = ["benchmark" "big-parallel" "kvm"];
  in [
    # Nix seems always try to build on the machine remotely
    # to make use of the local machine's high-performance CPU, do not set remote builder's maxJobs too high.
    # {
    #   # some of my remote builders are running NixOS
    #   # and has the same sshUser, sshKey, systems, etc.
    #   inherit
    #     sshUser
    #     # sshKey
    #     systems
    #     supportedFeatures;

    #   # the hostName should be:
    #   # 1. a hostname that can be resolved by DNS
    #   # 2. the ip address of the remote builder
    #   # 3. a host alias defined globally in /etc/ssh/ssh_config
    #   hostName = "Proteus-Desktop";
    #   maxJobs = 2; # remote builder's max-job
    #   speedFactor = 3; # speedFactor is a signed integer
    #   # https://github.com/ryan4yin/nix-config/issues/70
    # }
    # {
    #   inherit sshUser systems supportedFeatures;
    #   hostName = "Proteus-NixOS-1"; maxJobs = 1; speedFactor = 2;
    # }
    # {
    #   inherit sshUser systems supportedFeatures;
    #   hostName = "Proteus-NixOS-2"; maxJobs = 1; speedFactor = 0;
    # }
    # {
    #   inherit sshUser systems supportedFeatures;
    #   hostName = "Proteus-NixOS-3"; maxJobs = 1; speedFactor = 0;
    # }
    # {
    #   inherit sshUser systems supportedFeatures;
    #   hostName = "Proteus-NixOS-4"; maxJobs = 1; speedFactor = 0;
    # }
    # {
    #   inherit sshUser systems supportedFeatures;
    #   hostName = "Proteus-NixOS-5"; maxJobs = 1; speedFactor = 1;
    # }
  ];
  # optional, useful when the builder has a faster internet connection than yours
  nix.extraOptions = "builders-use-substitutes = true";
}

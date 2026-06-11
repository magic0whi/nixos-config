{
  description = "Proteus' nix configuration for NixOS & nix-darwin";
  inputs = {
    # Pinned as of 2026-06-05 18:10, branch: nixos-unstable
    nixpkgs.url = "github:magic0whi/nixpkgs/nixos-unstable";
    # nixpkgs.url = "path:/home/proteus/Works/Reference/nixpkgs";
    # Pinned as of 2026-04-14 17:55, branch: nixos-unstable
    # nixpkgs-postgresql.url = "github:NixOS/nixpkgs/4c1018dae018162ec878d42fec712642d214fdfa";
    # Pinned as of 2026-06-05 18:10, branch: master
    home-manager = {
      url = "github:nix-community/home-manager/447fd9ff62501dae7206dfe180ee89f8de27b7d5";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the
      # `inputs.nixpkgs` of the current flake, to avoid problems caused by
      # different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-06-05 18:12
    lanzaboote = {
      url = "github:nix-community/lanzaboote/e780b8e19d405b6906d759d270bbc125d221e81a";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-06-05 18:13
    impermanence = {
      url = "github:nix-community/impermanence/7b1d382faf603b6d264f58627330f9faa5cba149";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    # Pinned as of 2026-06-05 18:11
    nixpak = {
      url = "github:nixpak/nixpak/ad5ac7d24a505db29671edadfe6a8f985aa6e94e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-06-05 18:13
    sops-nix = {
      url = "github:Mic92/sops-nix/9ed65852b6257fbeae4355bc24ecfea307ca759a";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-06-05 18:14
    deploy-rs = {
      url = "github:magic0whi/deploy-rs/heitor-lassarote";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "lanzaboote/pre-commit/flake-compat";
      };
    };
    # Pinned as of 2026-06-05 18:14
    nix-darwin = {
      url = "github:magic0whi/nix-darwin/main";
      # url = "path:/Users/proteus/Works/Reference/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-06-05 18:14,
    catppuccin = {
      url = "github:catppuccin/nix/fd265813d18cc39bc0d27750c47a09766a535162";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-06-05 18:15
    disko = {
      url = "github:nix-community/disko/115e5211780054d8a890b41f0b7734cafad54dfe";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-06-05 18:16
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/4ed851c979641e28597a05086332d75cdc9e395f";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-06-05 18:16
    i915-sriov-dkms = {
      url = "github:strongtz/i915-sriov-dkms/2421d3ff8c27a967ffc2c6a1d19e0f3790ace5a0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-06-05 18:17
    treefmt-nix = {
      url = "github:numtide/treefmt-nix/db947814a175b7ca6ded66e21383d938df01c227";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-06-05 18:17
    niks3 = {
      url = "github:Mic92/niks3/c9a54708e881d51a76309168c5cda516bb2daeb0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    # Pinned as of 2026-06-05 17:32
    flake-parts.url = "github:hercules-ci/flake-parts/f7c1a2d347e4c52d5fb8d10cb4d94b5884e546fb";
    # Pinned as of 2026-06-05 17:32
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/c13ca9adcfb39914efcb88e18c628e95e2ba51e9.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/727d859b6f5f3289ce49fe26146b3f006387d457.tar.gz";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        lix.follows = "lix";
        flake-utils.inputs.systems.follows = "deploy-rs/utils/systems";
      };
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia/v4.7.7";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "riscv64-linux"
      ];
      imports = [
        ./checks.nix
        ./dev-shells.nix
        ./main.nix
        ./module-args.nix
        ./treefmt.nix
      ];
    };
}

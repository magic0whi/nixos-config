{
  description = "Proteus' nix configuration for NixOS & nix-darwin";
  inputs = {
    # Pinned as of 2026-06-05 18:10, branch: nixos-unstable
    nixpkgs.url = "github:magic0whi/nixpkgs/nixos-unstable";
    # nixpkgs.url = "path:/home/proteus/Works-References/nixpkgs";
    # Pinned as of 2026-04-14 17:55, branch: nixos-unstable
    # nixpkgs-postgresql.url = "github:NixOS/nixpkgs/4c1018dae018162ec878d42fec712642d214fdfa";
    # Pinned as of 2026-06-19 01:35, branch: master
    home-manager = {
      url = "github:nix-community/home-manager/8af17160d162bda6f0861c5c7249347c5df16635";
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
      # url = "path:/home/proteus/Works-References/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-06-19 00:05,
    catppuccin = {
      url = "github:catppuccin/nix/036c78ea4cd8a42c8546c6316a944fd7d59d4341";
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
    # https://github.com/noctalia-dev/noctalia-qs/commits/master/
    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs/d52844d40a697e47fea7bc0f1ec68aae9108ddf2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia/v4.7.7";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        noctalia-qs.follows = "noctalia-qs";
      };
    };
    niri-nix = {
      url = "https://codeberg.org/bananad3v/niri-nix/archive/841861b39dc0c4fe36ed2a92289b899fd4d956f2.tar.gz";
      # url = "path:/home/proteus/Works-References/niri-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter/f19b5fe2e20f1a80de178c8dedfbd838ce8eb2ca";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    prince213-nix-packages = {
      url = "github:Prince213/nix-packages/ccce5e6c4015bfa307469e470d777e1d1f471679";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
        systems.follows = "deploy-rs/utils/systems";
      };
    };
    dns = {
      url = "github:magic0whi/dns.nix";
      # url = "path:/home/proteus/Works-References/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    NixVirt = {
      url = "github:AshleyYakeley/NixVirt/6d213ab42f72ba41c2eb4e6bdb97581c0642d942";
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
        ./export-modules.nix
        ./main.nix
        ./module-args.nix
        ./treefmt.nix
      ];
    };
}

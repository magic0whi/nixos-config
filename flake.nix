{
  description = "Proteus Qian's nix configuration for NixOS & nix-darwin";
  inputs = {
    # Pinned as of 2026-05-04 17:55, branch: nixos-unstable
    # nixpkgs.url = "github:NixOS/nixpkgs/15f4ee454b1dce334612fa6843b3e05cf546efab";
    nixpkgs.url = "github:magic0whi/nixpkgs/main";
    # nixpkgs.url = "path:/home/proteus/Works/Reference/nixpkgs";
    # Pinned as of 2026-04-14 17:55, branch: nixos-unstable
    # nixpkgs-postgresql.url = "github:NixOS/nixpkgs/4c1018dae018162ec878d42fec712642d214fdfa";
    # Pinned as of 2026-05-26 19:37, branch: master
    home-manager = {
      url = "github:nix-community/home-manager/1a95e2efb477959b70b4a14c51035975c0481df6";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the
      # `inputs.nixpkgs` of the current flake, to avoid problems caused by
      # different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-04-07 06:58
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-04-07 06:53
    impermanence = {
      url = "github:nix-community/impermanence/7b1d382faf603b6d264f58627330f9faa5cba149";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    # Pinned as of 2026-04-07 06:54
    nixpak = {
      url = "github:nixpak/nixpak/4f8cbe437ba7e047ed4582b35b8140124b9562b5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-04-14 10:53
    sops-nix = {
      url = "github:Mic92/sops-nix/d4971dd58c6627bfee52a1ad4237637c0a2fb0cd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-04-07 06:56
    deploy-rs = {
      url = "github:serokell/deploy-rs/77c906c0ba56aabdbc72041bf9111b565cdd6171";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "lanzaboote/pre-commit/flake-compat";
      };
    };
    # Pinned as of 2026-05-04 15:06
    nix-darwin = {
      url = "github:magic0whi/nix-darwin/main";
      # url = "path:/Users/proteus/Works/Reference/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-05-27 00:24,
    catppuccin = {
      url = "github:catppuccin/nix/823da4d4f1160d7ac395fe459a4e33d9dfe57bb2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-04-07 06:59, tag v1.13.0
    disko = {
      url = "github:nix-community/disko/v1.13.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-04-07 07:00
    nixos-hardware.url = "github:NixOS/nixos-hardware/c775c2772ba56e906cbeb4e0b2db19079ef11ff7";
    # Pinned as of 2026-05-04 18:35, tag: 2026.03.05
    i915-sriov-dkms = {
      url = "github:strongtz/i915-sriov-dkms/2026.05.03";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-05-16 00:09
    treefmt-nix = {
      url = "github:numtide/treefmt-nix/790751ff7fd3801feeaf96d7dc416a8d581265ba";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niks3 = {
      url = "github:Mic92/niks3/v1.6.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
  };
  outputs = inputs: import ./main.nix inputs;
}

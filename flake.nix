{
  description = "Proteus' nix configuration for NixOS & nix-darwin";
  inputs = {
    # Pinned as of 2026-11-12, branch: nixos-unstable
    nixpkgs.url = "github:magic0whi/nixpkgs/nixos-unstable";
    # nixpkgs.url = "path:/Users/proteus/Proteus/Projects-Ref/nosync/nixpkgs";
    # nixpkgs-sing-box.url = "github:NixOS/nixpkgs/f9a75f41be3a74eab55d3a7679d34ad6cc0da977";
    # Pinned as of 2026-10-29, branch: master
    home-manager = {
      url = "github:nix-community/home-manager/82ce401aa350502897c3f2e85f384d61cd3b0b6d";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the
      # `inputs.nixpkgs` of the current flake, to avoid problems caused by
      # different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-11-12
    lanzaboote = {
      url = "github:nix-community/lanzaboote/c1c5edd31802d181c8aa2c71588995d93425d650";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-11-12
    impermanence = {
      url = "github:nix-community/impermanence/fa627f4c8b8e92f58f58a73d99ee4e1304e64eb2";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    # Pinned as of 2026-11-12
    nixpak = {
      url = "github:nixpak/nixpak/3b061c82f9ccb99973154ffced2391535da7b66b";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-11-12
    sops-nix = {
      url = "github:Mic92/sops-nix/fe7b4228405aeac2ce7192c2049a6e2bc8637082";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-11-12
    deploy-rs = {
      url = "github:serokell/deploy-rs/1cec0527bd09074bbee6d4461900ce5d58267217";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-10-21
    nix-darwin = {
      url = "github:magic0whi/nix-darwin/main";
      # url = "path:/Users/proteus/Proteus/Projects-Ref/nosync/nix-darwin";
      # url = "path:/home/proteus/Works-References/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-11-12
    catppuccin = {
      url = "github:catppuccin/nix/5a735352cd3535d43109415bcbb512a72304226a";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-11-12
    disko = {
      url = "github:nix-community/disko/1dd30c29c88d99ce295f15e27f93c49bc5fbae07";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-11-12
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/b6ca87f78ec5bafc4b2aef7b29803dcf419266af";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-11-12
    i915-sriov-dkms = {
      url = "github:strongtz/i915-sriov-dkms/2026.11.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-11-12
    treefmt-nix = {
      url = "github:numtide/treefmt-nix/0d6d739a833ba9a9c93034862e4a7b061a062a1c";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-10-27
    niks3 = {
      url = "github:Mic92/niks3/v1.16.2";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    # Pinned as of 2026-11-12
    flake-parts.url = "github:hercules-ci/flake-parts/ea2630b7470978622c7689a1ff75d2b389175399";
    # Pinned as of 2026-11-12, branch release-2.96
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/ff664d53ee6c84ca8689f16e0642c65c85aaeac5.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-11-12
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/9311ca94aac0ff3378ab4eea887284d11de94158.tar.gz";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        lix.follows = "lix";
      };
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia/v5.5.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter/af0bf4b1e1c40738db917b04c9c0563b4f718953";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dns = {
      url = "github:magic0whi/dns.nix";
      # url = "path:/home/proteus/Works-References/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-11-12
    NixVirt = {
      url = "github:AshleyYakeley/NixVirt/11e2b2c0492aeff3fe3dea9000832d7694c47dfe";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/48409beb41e8e28b64e8160ca82d8a93fb628963";
      # inputs.nixpkgs.follows = "nixpkgs"; # nixvim recommend against using follows
    };
    # Pinned as of 2026-11-12
    helix = {
      url = "github:helix-editor/helix/a714a818a3a4f6dd5aad3b003a78692f90a1703f";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dev-flake = {
      url = "github:magic0whi/dev_flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
        flake-parts.follows = "flake-parts";
      };
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

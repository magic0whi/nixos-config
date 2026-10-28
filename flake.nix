{
  description = "Proteus' nix configuration for NixOS & nix-darwin";
  inputs = {
    # Pinned as of 2026-06-05 18:10, branch: nixos-unstable
    nixpkgs.url = "github:magic0whi/nixpkgs/nixos-unstable";
    # nixpkgs-old.url = "github:magic0whi/nixpkgs/45e757b72a4cf53734c4a816f02580665ac20454";
    # nixpkgs.url = "path:/Users/proteus/Proteus/Projects-Ref/nosync/nixpkgs";
    # Pinned as of 2026-04-14 17:55, branch: nixos-unstable
    # nixpkgs-postgresql.url = "github:NixOS/nixpkgs/4c1018dae018162ec878d42fec712642d214fdfa";
    # Pinned as of 2026-10-29, branch: master
    home-manager = {
      url = "github:nix-community/home-manager/095fef2f265c3c0da4fe315efba8f8a04495ab34";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the
      # `inputs.nixpkgs` of the current flake, to avoid problems caused by
      # different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-10-07 16:48
    lanzaboote = {
      url = "github:nix-community/lanzaboote/ba33415d747d8dedd2931af107521634f1f2e8a8";
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
    # Pinned as of 2026-10-07 15:07
    sops-nix = {
      url = "github:Mic92/sops-nix/dcd241ba97088c22569d1573286e1b9daad340c0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-10-08 08:14
    deploy-rs = {
      url = "github:serokell/deploy-rs/45ba3f8c5cb28396fff71671806e2550b464ac86";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-10-21
    nix-darwin = {
      url = "github:magic0whi/nix-darwin/main";
      # url = "path:/Users/proteus/Proteus/Projects-Ref/nosync/nix-darwin";
      # url = "path:/home/proteus/Works-References/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-10-29
    catppuccin = {
      url = "github:catppuccin/nix/ddfe53d3304399d50a89ef6503b6ca1be9349fab";
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
    # Pinned as of 2026-10-08 08:25
    i915-sriov-dkms = {
      url = "github:strongtz/i915-sriov-dkms/f4cb98f4c28e1f3ac78ca88501a87c86d0c21a88";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-06-05 18:17
    treefmt-nix = {
      url = "github:numtide/treefmt-nix/db947814a175b7ca6ded66e21383d938df01c227";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-10-27
    niks3 = {
      url = "github:Mic92/niks3/v1.15.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    # Pinned as of 2026-06-05 17:32
    flake-parts.url = "github:hercules-ci/flake-parts/f7c1a2d347e4c52d5fb8d10cb4d94b5884e546fb";
    # Pinned as of 2026-10-29, branch release-2.96
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/5bd6eaabd8bb9cdddadc3f8481327702e4d37cc3.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned as of 2026-10-29
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/9311ca94aac0ff3378ab4eea887284d11de94158.tar.gz";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        lix.follows = "lix";
      };
    };
    # https://github.com/noctalia-dev/noctalia-qs/commits/master/
    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs/d52844d40a697e47fea7bc0f1ec68aae9108ddf2";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia/v4.7.7";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        noctalia-qs.follows = "noctalia-qs";
      };
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter/f19b5fe2e20f1a80de178c8dedfbd838ce8eb2ca";
      inputs.nixpkgs.follows = "nixpkgs";
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
    nixvim = {
      url = "github:nix-community/nixvim/48409beb41e8e28b64e8160ca82d8a93fb628963";
      # inputs.nixpkgs.follows = "nixpkgs"; # nixvim recommend against using follows
    };
    # Pinned as of 2026-10-07
    # NOTE: https://github.com/helix-editor/helix/issues/16347
    helix = {
      url = "github:helix-editor/helix/86d7b61520e4bbc58d1d794dae8708e544969642";
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

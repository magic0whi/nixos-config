{ inputs, mylib }:
{
  common =
    let
      common = "modules/common";
    in
    {
      base = map mylib.relToRoot [
        "modules/vars/forward-auth-services.nix"
        "modules/vars/host-addrs.nix"

        "${common}/debug.nix"
        "${common}/easytier.nix"
        "${common}/misc.nix"
        "${common}/nix.nix"
        "${common}/secrets.nix"
        "${common}/shell.nix"
      ];
      baseOverlays = with inputs; [
        helix.overlays.default
        # Take sing-box from a newer nixpkgs
        # (_: prev: { inherit (nixpkgs-sing-box.legacyPackages.${prev.stdenv.hostPlatform.system}) sing-box; })
        # Take opencode 2.3.0 from a newer nixpkgs
        (_: prev: { inherit (nixpkgs-opencode.legacyPackages.${prev.stdenv.hostPlatform.system}) opencode; })
      ];
      seat = map mylib.relToRoot [
        "${common}/fonts.nix"
        "${common}/niks3-auto-upload.nix"
        "${common}/packages.nix"
        "${common}/sing-box-client-mobile.nix"
        "${common}/sing-box-client.nix"
        "${common}/ssh.nix"
      ];
      services =
        let
          services = "modules/services";
        in
        map mylib.relToRoot [
          "${services}/authelia-online.nix"
          "${services}/garage.nix"
          "${services}/prometheus-exporters.nix"
          "${services}/sing-box.nix"
          "${services}/traefik.nix"
        ];
    };

  nixos =
    let
      headless = "modules/nixos_headless";
      gui = "modules/nixos_gui";
    in
    {
      base =
        (with inputs; [
          disko.nixosModules.disko
          impermanence.nixosModules.default
          lix-module.nixosModules.default
          sops-nix.nixosModules.sops
        ])
        ++ map mylib.relToRoot [
          "${headless}/easytier.nix"
          "${headless}/firewall-common.nix"
          "${headless}/impermanence.nix"
          "${headless}/misc.nix"
          "${headless}/sssd.nix"
          "${headless}/systemd-resolved.nix"
        ];

      seat = {
        tui = [
          inputs.lanzaboote.nixosModules.default
          inputs.niks3.nixosModules.niks3-auto-upload
        ]
        ++ map mylib.relToRoot [
          "modules/vars/hm-firewall.nix"

          "${headless}/binfmt.nix"
          "${headless}/fhs.nix"
          "${headless}/fonts.nix"
          "${headless}/krnl-compat.nix"
          "${headless}/packages.nix"
          "${headless}/power-mgmt.nix"
          "${headless}/remote-build.nix"
          "${headless}/scx-loader.nix"
          "${headless}/secureboot.nix"
          "${headless}/sing-box-client-mobile.nix"
          "${headless}/sing-box-client.nix"
          "${headless}/zfs.nix"

          "${gui}/kmscon.nix"
        ];

        gui =
          (with inputs; [ noctalia-greeter.nixosModules.default ])
          ++ map mylib.relToRoot [
            "${gui}/bluetooth.nix"
            "${gui}/peripherals.nix"
            "${gui}/pipewire.nix"
            "${gui}/security.nix"
            "${gui}/steam.nix"
            "${gui}/wayland.nix"
          ];

        guiOverlays = [
          inputs.noctalia-greeter.overlays.default
        ]
        ++ map (file: import file) (
          map mylib.relToRoot [
            "modules/overlays/localsend.nix"
            "modules/overlays/nixpaks"
          ]
        );
      };
    };

  darwin =
    with inputs;
    [
      lix-module.darwinModules.default
      sops-nix.darwinModules.sops
      niks3.darwinModules.niks3-auto-upload
    ]
    ++ map mylib.relToRoot [ "modules/darwin" ];

  hm = {
    common =
      let
        headless = "modules/common_hm_headless";
        gui = "modules/common_hm_gui";
      in
      {
        base =
          with inputs;
          [
            catppuccin.homeModules.catppuccin
          ]
          ++ map mylib.relToRoot [
            "${headless}/helix.nix"
            "${headless}/misc.nix"
            "${headless}/shell.nix"
          ];

        seat =
          with inputs;
          [
            sops-nix.homeModules.sops
            noctalia.homeModules.default
            nixvim.homeModules.nixvim
          ]
          ++ map mylib.relToRoot [
            "modules/vars_hm/hm-firewall.nix"

            "${headless}/ai"
            "${headless}/cloud-providers.nix"
            "${headless}/dev-env.nix"
            "${headless}/file_sharing.nix"
            "${headless}/git.nix"
            "${headless}/gpg.nix"
            "${headless}/nix.nix"
            "${headless}/nvim"
            "${headless}/packages.nix"
            "${headless}/secrets.nix"
            "${headless}/ssh.nix"
            "${headless}/syncthing.nix"
            "${headless}/zellij.nix"
            # "${headless}/debug.nix"

            "${gui}/anki.nix"
            "${gui}/mpv.nix"
            "${gui}/misc.nix"
            "${gui}/ghostty.nix"
            "${gui}/packages.nix"
            "${gui}/pdf-reader.nix"
          ];
      };

    nixos =
      let
        headless = "modules/nixos_hm_headless";
        gui = "modules/nixos_hm_gui";
      in
      map mylib.relToRoot [
        "${headless}/udiskie.nix"

        "${gui}/fcitx5.nix"
        "${gui}/theming.nix"
        "${gui}/misc.nix"
        "${gui}/niri"
        "${gui}/noctalia.nix"
        "${gui}/obs-studio.nix"
        "${gui}/packages.nix"
        "${gui}/xdg.nix"
      ];

    darwin = map mylib.relToRoot [ "modules/darwin_hm" ];
  };
}

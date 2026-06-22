{ inputs, mylib }:
{
  common =
    let
      common = "modules/common";
    in
    {
      base = map mylib.relativeToRoot [
        "modules/variables/host-addrs.nix"
        "${common}/debug.nix"
        "${common}/easytier.nix"
        "${common}/misc.nix"
        "${common}/nix.nix"
        "${common}/secrets.nix"
        "${common}/shell.nix"
        "${common}/tailscale.nix"
      ];
      baseOverlays = [ inputs.prince213-nix-packages.overlays.default ];
      seat = map mylib.relativeToRoot [
        "modules/variables/sing-box-subscribe.nix"
        "${common}/sing-box-client.nix"
        "${common}/fonts.nix"
        "${common}/packages.nix"
      ];
      extra = map mylib.relativeToRoot [ "${common}/ssh.nix" ];
      services = map mylib.relativeToRoot [ "modules/services/sing-box.nix" ];
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
          niks3.nixosModules.niks3-auto-upload
          sops-nix.nixosModules.sops
        ])
        ++ map mylib.relativeToRoot [
          "${headless}/easytier.nix"
          "${headless}/firewall-common.nix"
          "${headless}/impermanence.nix"
          "${headless}/misc.nix"
          "${headless}/niks3-auto-upload.nix"
          "${headless}/sssd.nix"
          "${headless}/systemd-resolved.nix"
        ];

      seat = {
        tui = map mylib.relativeToRoot [
          "modules/nixos_headless/sing-box-subscribe.nix"
          "${headless}/firewall-client.nix"
          "${headless}/fhs.nix"
          "${headless}/fonts.nix"
          "${headless}/scx-loader.nix"
          "${gui}/kmscon.nix"
        ];

        gui =
          (with inputs; [ noctalia-greeter.nixosModules.default ])
          ++ map mylib.relativeToRoot [
            "${gui}/steam.nix"
            "${gui}/wayland.nix"
          ];

        guiOverlays = [
          inputs.noctalia-greeter.overlays.default
        ]
        ++ map (file: import file) (map mylib.relativeToRoot [ "modules/overlays/nixpaks" ]);
      };

      extra = [
        inputs.lanzaboote.nixosModules.default
      ]
      ++ map mylib.relativeToRoot [
        "${headless}/packages.nix"
        "${headless}/power-mgmt.nix"
        "${headless}/remote-build.nix"
        "${headless}/secureboot.nix"
        "${headless}/krnl-compat.nix"
        "${headless}/zfs.nix"
        "${gui}/peripherals.nix"
        "${gui}/bluetooth.nix"
        "${gui}/pipewire.nix"
      ];
    };

  darwin =
    with inputs;
    [
      lix-module.darwinModules.default
      sops-nix.darwinModules.sops
    ]
    ++ map mylib.relativeToRoot [ "modules/darwin" ];

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
          ++ map mylib.relativeToRoot [
            "${headless}/custom-scripts.nix"
            "${headless}/helix.nix"
            "${headless}/misc.nix"
            "${headless}/shell.nix"
          ];

        seat =
          with inputs;
          [
            sops-nix.homeModules.sops
            noctalia.homeModules.default
            niri-nix.homeModules.default
          ]
          ++ map mylib.relativeToRoot [
            # "${headless}/debug.nix"
            "${headless}/syncthing.nix"
            "${headless}/dev-env.nix"
            "${headless}/file_sharing.nix"
            "${headless}/git.nix"
            "${headless}/gpg.nix"
            "${headless}/nix.nix"
            "${headless}/packages.nix"
            "${headless}/zellij.nix"

            "${gui}/mpv.nix"
            "${gui}/misc.nix"
            "${gui}/ghostty.nix"
            "${gui}/packages.nix"
            "${gui}/alacritty.nix"
            "${gui}/pdf-reader.nix"
          ];
      };

    nixos =
      let
        headless = "modules/nixos_hm_headless";
        gui = "modules/nixos_hm_gui";
      in
      map mylib.relativeToRoot [
        "${headless}/udiskie.nix"

        "${gui}/fcitx5.nix"
        "${gui}/gtk_and_qt.nix"
        "${gui}/hypridle.nix"
        "${gui}/misc.nix"
        "${gui}/niri"
        "${gui}/noctalia.nix"
        "${gui}/obs-studio.nix"
        "${gui}/packages.nix"
        "${gui}/xdg.nix"
      ];

    darwin = map mylib.relativeToRoot [ "modules/darwin_hm" ];
  };
}

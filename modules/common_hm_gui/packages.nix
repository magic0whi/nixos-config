{
  lib,
  pkgs,
  xdgRel,
  ...
}:
{
  networking.firewall =
    let
      localsend_port = 53317;
    in
    {
      allowedTCPPorts = [ localsend_port ];
      allowedUDPPorts = [ localsend_port ];
    };
  home.packages =
    (with pkgs; [
      feishin
      localsend # Alternative to AirDrop
      libnotify # notify-send

      moonlight-qt # Remote desktop client

      ## Games
      # modrinth-app
      # r2modman
      # prismlauncher # A free, open source launcher for Minecraft
      # winetricks # A script to install DLLs needed to work around problems in Wine

      ## Creative
      # kicad # Consumes a lot of storage, as of 7/24/2025, it's broken on macOS
      # kicad-small # 3D printing, eletrical engineering (without 3D models)
      geogebra6 # Dynamic mathematics software with graphics, algebra and spreadsheets
      code-cursor # An AI code editor
      musescore # Music notation
      # reaper # Audio production

      ## 2D game design
      # aseprite # Animated sprite editor & pixel art tool

      # Dev-tools
      # insomnia # REST client
      # wireshark # Network analyzer

      # Video/audio tools
      # cava # For visualizing audio
    ])
    ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) (
      with pkgs;
      [
        blender # 3D modeling, currently broken on darwin

        # Vector graphics
        (inkscape-with-extensions.override {
          inkscapeExtensions = with inkscape-extensions; [ textext ];
        })

        super-productivity
      ]
    );
  home.persistence."/persistent".directories = [
    "${xdgRel.configHome}/blender"
    "${xdgRel.configHome}/feishin"
    "${xdgRel.configHome}/superProductivity"
  ];
  programs = {
    discord.enable = true; # Update too frequently, it is recommend to use the web version instead
    keepassxc = {
      enable = true;
      # https://github.com/NixOS/nixpkgs/issues/241103#issuecomment-7109669782
      # If you have Developer Subscription: https://github.com/tjni/nix-darwin-codesign
      package =
        if pkgs.stdenv.hostPlatform.isDarwin then
          pkgs.stdenv.mkDerivation rec {
            pname = "keepassxc-bin";
            version = pkgs.keepassxc.version;

            src = pkgs.fetchurl {
              url = "https://github.com/keepassxreboot/keepassxc/releases/download/${version}/KeePassXC-${version}-1-arm64.dmg";
              sha256 = "hfDnXiWO9RPw/H9b9HDK0JQ7fX6BkbIXH5iYrTLmK5w=";
            };

            nativeBuildInputs = [ pkgs.undmg ];

            sourceRoot = ".";

            installPhase = ''
              set -e
              runHook preInstall
              mkdir -p "$out/Applications"
              cp -r -- *.app "$out/Applications/"
              runHook postInstall
            '';

            dontFixup = true; # Official KeePassXC.dmg is notarized.
          }
        else
          pkgs.keepassxc;
    };
  };
}

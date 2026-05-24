{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    localsend # Alternative to AirDrop
    # discord # Update too frequently, use the web version instead

    libnotify # notify-send

    moonlight-qt # Remote desktop client

    ## Games
    # modrinth-app
    # prismlauncher # A free, open source launcher for Minecraft
    # winetricks # A script to install DLLs needed to work around problems in Wine

    ## Creative
    geogebra6 # Dynamic mathematics software with graphics, algebra and spreadsheets
    (
      if pkgs.stdenv.isLinux
      then
        (anki-bin.overrideAttrs (prev: {
          # Add env 'QT_IM_MODULE=fcitx' to anki.desktop
          # TIP: `builtins.trace test.buildCommand test.buildCommand` is useful in debugging
          buildCommand = ''
            ${prev.buildCommand}
            unpacked=$(grep -Po '(?<=cp -R )\/nix\/store\/\S+(?=\/share\/applications)' <<< '${prev.buildCommand}')
            perm_bak=$(stat -c '%a' $out/share/applications/anki.desktop)
            chmod 644 $out/share/applications/anki.desktop
            sed 's/^Exec=\(anki\)/Exec=env XCURSOR_SIZE=${toString config.home.pointerCursor.size} QT_IM_MODULE=fcitx \1/' $unpacked/share/applications/anki.desktop > $out/share/applications/anki.desktop
            chmod $perm_bak $out/share/applications/anki.desktop
          '';
        }))
      else anki-bin
    )
    code-cursor # An AI code editor
    # blender # 3D modeling, currently broken on darwin
    musescore # Music notation
    # reaper # Audio production

    # Dev-tools
    # insomnia # REST client
    # wireshark # Network analyzer

    super-productivity
    nuclear
  ];
}

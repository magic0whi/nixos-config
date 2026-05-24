{pkgs, ...}: {
  home.packages = with pkgs; [
    telegram-desktop # Instant messaging

    # foliate # e-book viewer(.epub/.mobi/...),do not support .pdf

    ## Remote Desktop (RDP protocol)
    # remmina
    # freerdp # Required by remmina

    ## Custom Hardened Packages
    # nixpaks.qq
    # nixpaks.qq-desktop-item
    # nixpaks.wechat-uos
    # nixpaks.wechat-uos-desktop-item
    # wechat-uos

    ## Games
    # nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.osu-laser-bin
    # gamescope # SteamOS session compositing window manager

    ## Creative
    # blender
    inkscape # Vector graphics
    # gimp3 # Image editing, I prefer using figma in browser instead of this one
    # krita # digital painting
    # sonic-pi # music programming
    # kicad # Consumes a lot of storage, as of 7/24/2025, it's broken on macOS
    # kicad-small # 3D printing, eletrical engineering (without 3D models)

    ## 2D game design
    # ldtk # A modern, versatile 2D level editor
    # aseprite # Animated sprite editor & pixel art tool

    # virt-viewer # VNC connect to VM, used by kubevirt

    # Audio control
    pavucontrol
    pulsemixer
    imv # simple image viewer

    # Video/audio tools
    # cava # For visualizing audio
    # libva-utils
    # vdpauinfo
    # vulkan-tools
    # mesa-demos # Run `nix shell nixpkgs#mesa-demos -c glxgears` instead
    # clinfo # Run `nix run nixpkgs#clinfo` instead
  ];
}

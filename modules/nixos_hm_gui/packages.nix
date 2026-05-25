{ pkgs, ... }:
{
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
    # gimp # Image editing, I prefer using figma in browser instead of this one
    # krita # Digital painting
    # sonic-pi # Music programming

    ## 2D game design
    # ldtk # A modern, versatile 2D level editor

    # virt-viewer # VNC connect to VM, used by kubevirt

    # Audio control
    pavucontrol
    pulsemixer
    imv # simple image viewer

    # Video/audio tools
    # libva-utils
    # vdpauinfo
    # vulkan-tools
    # mesa-demos # Run `nix shell nixpkgs#mesa-demos -c glxgears` instead
    # clinfo # Run `nix run nixpkgs#clinfo` instead
  ];
}

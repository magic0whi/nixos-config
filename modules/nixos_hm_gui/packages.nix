{ pkgs, ... }:
{
  home.packages = with pkgs; [
    telegram-desktop # Instant messaging
    imv # simple image viewer
    loupe # Simple image viewer application written with GTK4 and Rust
    tor-browser

    # foliate # e-book viewer(.epub/.mobi/...),do not support .pdf

    ## Remote Desktop (RDP protocol)
    # remmina
    # freerdp

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

    gnuplot

    # Video/audio tools
    # libva-utils # vainfo
    # vdpauinfo
    # vulkan-tools
    # mesa-demos # Run `nix shell nixpkgs#mesa-demos -c glxgears` instead
    # clinfo # Run `nix run nixpkgs#clinfo` instead
  ];
}

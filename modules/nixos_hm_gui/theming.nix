{
  config,
  pkgs,
  ...
}:
{
  # If your themes for mouse cursor, icons or windows don’t load correctly, try setting them with `home.pointerCursor`
  # and `gtk.theme`, which enables a bunch of compatibility options that should make the themes load in all situations
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };
  # xresources.properties = { # Set DPI for 4k monitor
  #   "Xft.dpi" = 150; # dpi for Xorg's font
  #   "*.dpi" = 150; # or set a generic dpi
  # };
  gtk = {
    enable = true;
    font = {
      name = "Inter Nerd Font";
      package = null; # Already in 'fonts.packages' system-wide
      size = 11;
    };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark"; # GTK4 prefer dark
  qt = {
    enable = true;
    platformTheme = {
      name = "qt6ct";
      # HM only maps "qtct" to packages, so "qt6ct" alone installs nothing and the platform theme silently fails to load
      package = pkgs.qt6Packages.qt6ct;
    };
    qt6ctSettings.Appearance = {
      style = "kvantum";
      # Without an icon theme, qt6ct falls back to hicolor only and themed icons (e.g. input-keyboard) are missing
      icon_theme = config.gtk.iconTheme.name;
    };
    style.name = "kvantum";
  };
}

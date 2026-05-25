{ pkgs, ... }:
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true; # Hyprland supports it
    fcitx5.addons = with pkgs; [
      qt6Packages.fcitx5-configtool # Requires manually enable rime using configtool
      qt6Packages.fcitx5-chinese-addons
      # Chinese Traditional
      fcitx5-chewing
      fcitx5-mozc
      fcitx5-rime
      # Pinyin Dictionary
      fcitx5-pinyin-zhwiki
      fcitx5-pinyin-moegirl
      fcitx5-pinyin-minecraft

      fcitx5-gtk # GTK IM module
    ];
    fcitx5.settings = {
      addons.classicui.globalSection = {
        "Vertical Candidate List" = false;
        PerScreenDPI = true;
        WheelForPaging = true;
        Font = "Sans 10";
        MenuFont = "Sans 10";
        TrayFont = "Sans Bold 10";
        TrayOutlineColor = "#000000";
        TrayTextColor = "#ffffff";
        PreferTextIcon = false;
        ShowLayoutNameInIcon = true;
        UseInputMethodLangaugeToDisplayText = true;
        ForceWaylandDPI = 0; # Force font DPI on Wayland
        DarkTheme = "catppuccin-mocha-pink"; # catppuccin-nix doesn't set it
      };
      inputMethod = {
        GroupOrder."0" = "Default";
        GroupOrder."1" = "Rime";
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "keyboard-us";
        };
        "Groups/0/Items/0".Name = "keyboard-us";
        "Groups/0/Items/1".Name = "pinyin";
        "Groups/0/Items/2".Name = "chewing";
        "Groups/0/Items/3".Name = "mozc";
        "Groups/1" = {
          Name = "Rime";
          "Default Layout" = "us";
          DefaultIM = "rime";
        };
        "Groups/1/Items/0".Name = "rime";
      };
    };
  };
}

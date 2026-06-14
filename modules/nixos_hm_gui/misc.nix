{ lib, pkgs, ... }:
{
  # BEGIN niri.nix
  wayland.windowManager.niri.enable = true;
  # NOTE: this executable is used by greetd to start a wayland session when system boot up with such a
  # vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config in NixOS
  # module
  home.file.".wayland-session" = {
    source = pkgs.writeScript "init-session" ''
      # trying to stop a previous niri session
      systemctl --user is-active niri.service && systemctl --user stop niri.service
      # and then we start a new one
      systemctl --user start --wait niri.service
    '';
    executable = true;
  };
  wayland.windowManager.niri = {
    settings.workspaces = [
      "0other"
      "1terminal"
      "2browser"
      "3chat"
      "4gaming"
      "5music"
      "6file"
      "7"
      "8"
      "9"
    ];
    extraConfig = lib.mkMerge [
      (lib.mkBefore ''
        include "./keybindings.kdl"
        include "./window-rules.kdl"
        include "./niri-hardware.kdl"
        include "./noctalia-shell.kdl"
      '')
      ''
        // TIP: `/-` comments out the following node.
        input {
          touchpad {
            tap // tap-to-click
            dwt // disable-when-typing.
            natural-scroll // inverts the scrolling direction.
          }
        }

        // Clients will be informed that they are tiled, removing some client-side rounded corners and window frame.
        // After enabling or disabling this, you need to restart the apps for this to take effect.
        //
        // By default focus border are rendered as a solid background rectangle behind windows. This is because windows using
        // client-side decorations can have an arbitrary shape.
        //
        // Niri will draw focus ring and border *around* windows that agree to omit their client-side decorations.
        //
        // Alternatively, you can override it with a window rule called
        // `draw-border-with-background`.
        prefer-no-csd

        layout {
          gaps 8 // In logical pixels.
          focus-ring {
            // off
            width 4
            active-gradient from="#e5989b" to="#ffb4a2" angle=45 in="oklch longer hue"
            // The focus ring only draws around the active window, so the only place where you can see its inactive-color is
            // on other monitors.
            inactive-color "#595959aa"
          }
        }
        window-rule {
          geometry-corner-radius 20 // Rounded logical corners
          clip-to-geometry true // Clips window contents to the rounded corner boundaries.
        }

        hotkey-overlay {
          skip-at-startup //disable the "Important Hotkeys" pop-up at startup.
          hide-not-bound
        }
        screenshot-path null // Disable saving screenshots to disk.

        // https://niri-wm.github.io/niri/Configuration%3A-Animations.html
        // TODO
        // animations { }
      ''
    ];

  };
  xdg.configFile = {
    "niri/niri-hardware.kdl".source = ./_niri/niri-hardware.kdl;
    "niri/noctalia-shell.kdl".source = ./_niri/noctalia-shell.kdl;
    "niri/window-rules.kdl".source = ./_niri/window-rules.kdl;
  };
  # END niri.nix
  ## BEGIN peripherals.nix
  services.playerctld.enable = true; # playerctl
  ## END peripherals.nix

  ## BEGIN fonts.nix
  # This allows fontconfig to discover fonts and configurations installed through home.packages, but I manage fonts at
  # system-level, not user-level
  # fonts.fontconfig.enable = true;
  ## END fonts.nix

  ## BEGIN gpg.nix
  services.gpg-agent.pinentry.package = pkgs.pinentry-qt; # GPG agent with pinentry-qt
  ## END gpg.nix

  ## BEGIN syncthing_tray.nix
  services.syncthing.tray.enable = true; # Only supports Linux platform
  ## END syncthing_tray.nix

  ## BEGIN browsers.nix
  services.psd.enable = true; # profile-sync-daemon
  # Enable Ozone Wayland support in Chromium and Electron based applications
  home.sessionVariables.NIXOS_OZONE_WL = "1";
  ## END browsers.nix
  ## START game.nix
  programs.lutris.enable = true;
  ## END game.nix
}

{
  # https://docs.noctalia.dev/noctalia/compositor-settings/niri/
  wayland.windowManager.niri.extraConfig = ''
    // =========================== noctalia.kdl ===============================
    spawn-at-startup "noctalia"

    // Floating Noctalia settings window.
    window-rule {
      match app-id="dev.noctalia.Noctalia"
      open-floating true
      default-column-width { fixed 1080; }
      default-window-height { fixed 920; }
    }

    // Allows notification actions and window activation from Noctalia.
    debug { honor-xdg-activation-with-invalid-serial; }

    // Blurred overview wallpaper, requires `backdrop.enabled` in Noctalia.
    layer-rule {
      match namespace="^noctalia-backdrop"
      place-within-backdrop true
    }
    // ========================================================================
  '';
}

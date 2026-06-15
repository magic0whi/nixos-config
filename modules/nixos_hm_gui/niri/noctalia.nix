{
  # https://docs.noctalia.dev/v4/getting-started/compositor-settings/niri/
  wayland.windowManager.niri.extraConfig = ''
    // =========================== noctalia.kdl ===============================
    // Allows notification actions and window activation from Noctalia.
    debug { honor-xdg-activation-with-invalid-serial; }

      // Noctalia: use niri spawn-at-startup (systemd user service is deprecated upstream).
      // https://docs.noctalia.dev/getting-started/compositor-settings/niri/
      spawn-at-startup "noctalia"

    // Set the overview wallpaper on the backdrop.
    layer-rule {
      match namespace="^noctalia-overview*"
      place-within-backdrop true
    }
    // ========================================================================
  '';
}

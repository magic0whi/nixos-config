{
  config,
  const,
  lib,
  pkgs,
  ...
}:
{
  services.wluma = {
    enable = true;
    package = pkgs.wluma.overrideAttrs (old: rec {
      version = "5.0.4";
      src = pkgs.fetchFromGitHub {
        owner = "max-baz";
        repo = "wluma";
        tag = version;
        hash = "sha256-74DUlFkLK4RncESgKTmUfLH6aZPnDPzrISpJ8OKc0sg=";
      };
      # Cargo.lock has no git sources, so importCargoLock can
      # vendor straight from the lockfile without computing a cargoHash.
      cargoDeps = pkgs.rustPlatform.importCargoLock { lockFile = "${src}/Cargo.lock"; };
      buildInputs = old.buildInputs ++ [ pkgs.pipewire ]; # 5.x adds PipeWire dependency
    });

    # TIP: to debug:
    # systemctl --user set-environment RUST_LOG=trace
    # systemctl --user restart wluma
    # journalctl --user -fu wluma -o cat
    # systemctl --user unset-environment RUST_LOG && systemctl --user restart wluma
    #
    # 5.0.4 also has a CLI: `wluma status [--json]`, `watch`, `get`, `set`,
    # `pause`, `resume`, `toggle`, `version`.
    settings =
      let
        noctalia_cfg = config.programs.noctalia.settings;
      in
      {
        als.webcam.video = 0;
        # Alternative: time-based ALS.
        # als.time.levels = {
        #   "0" = 0;
        #   "7" = 10;
        #   "9" = 40;
        #   "12" = 70;
        #   "16" = 50;
        #   "19" = 10;
        #   "21" = 0;
        # };

        idle.enabled = !noctalia_cfg.idle.behavior.lock.enabled;

        output =
          let
            gamma = !noctalia_cfg.nightlight.enabled;
          in
          {
            backlight = lib.singleton {
              inherit gamma;
              name = "eDP-1";
              # No udev rule needed as brightness goes through logind's D-Bus SetBrightness
              path = "/sys/class/backlight/intel_backlight";
              capturer = "none";
            };
            ddcutil = lib.singleton {
              inherit gamma;
              name = "DP-3";
              identifier = "C340SCA"; # ddcutil detect --terse -> "Monitor: IPS:C340SCA:"
              vulkan_device = "/dev/dri/${if config.hardware.nvidia.sync then const.dgpu_sym_name else const.igpu_sym_name}";
            };
          };
      };
  };
}

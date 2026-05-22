{
  # config,
  # lib,
  # pkgs,
  ...
}: {
  services.elephant.enable = true;
  services.walker = {
    enable = true;
    systemd.enable = true;
  };
  # options.programs.anyrun = {
  #   menu_script = lib.mkOption {
  #     type = lib.types.path;
  #     description = "Path to the Anyrun menu wrapper script";
  #     default = pkgs.writeShellScript "menu" ''
  #       set -eufo pipefail
  #       anyrun close || true
  #       anyrun
  #     '';
  #   };
  #   clip_script = lib.mkOption {
  #     type = lib.types.path;
  #     description = "Path to the Anyrun clip_manager wrapper script";
  #     default = pkgs.writeShellScript "clip-manager" ''
  #       set -eufo pipefail
  #       anyrun close || true
  #       cliphist list | anyrun --plugins ${config.programs.anyrun.package}/lib/libstdin.so --show-results-immediately true | cliphist decode | wl-copy
  #     '';
  #   };
  # };
  # config = {
  #   systemd.user.services.anyrun = {
  #     Unit = {
  #       Description = "Anyrun daemon";
  #       PartOf = ["graphical-session.target"];
  #       After = ["graphical-session.target"];
  #     };
  #     Service = {
  #       ExecStart = "${lib.getExe config.programs.anyrun.package} daemon";
  #       Restart = "on-failure";
  #     };
  #     Install.WantedBy = ["graphical-session.target"];
  #   };
  #   programs.anyrun = {
  #     enable = true;
  #     config = {
  #       plugins = let
  #         pkg = config.programs.anyrun.package;
  #       in [
  #         "${pkg}/lib/libapplications.so" # Launch applications
  #         # "${pkg}/lib/libdictionary.so" # Look up word definitions using the Free Dictionary API
  #         # "${pkg}/lib/libnix_run.so" # search & run graphical apps from nixpkgs via `nix run`, without installing it
  #         "${pkg}/lib/librink.so" # A simple calculator plugin
  #         # "${pkg}/lib/libstdin.so" # Required by cliphist
  #         # "${pkg}/lib/libsymbols.so" # Look up unicode symbols and custom user defined symbols
  #         # "${pkg}/lib/libtranslate.so" # ":zh <text to translate>" Quickly translate text using the Google Translate API
  #       ];
  #       x.fraction = 0.5; # At the middle of the screen
  #       y.fraction = 0.05; # At the top of the screen
  #       width.fraction = 0.3; # 30% of the screen
  #       closeOnClick = true;
  #       showResultsImmediately = true;
  #     };
  #     # From https://github.com/ryan4yin/nix-config/blob/e902a9bdb1819da14bc69745fc657b1fcfac7afd/home/linux/gui/base/desktop/conf/anyrun/style.css
  #     extraCss = ''
  #       /* ===== Color variables ===== */
  #       :root {
  #         --bg-color: #313244;
  #         --fg-color: #cdd6f4;
  #         --primary-color: #89b4fa;
  #         --secondary-color: #cba6f7;
  #         --border-color: var(--primary-color);
  #         --selected-bg-color: var(--primary-color);
  #         --selected-fg-color: var(--bg-color);
  #       }

  #       /* ===== Global reset ===== */
  #       * {
  #         all: unset;
  #         font-family: Symbols Nerd Font, Inter Nerd Font, sans-serif;
  #       }

  #       /* ===== Transparent window ===== */
  #       window {
  #         background: transparent;
  #       }

  #       /* ===== Main container ===== */
  #       box.main {
  #         border-radius: 16px;
  #         background-color: color-mix(in srgb, var(--bg-color) 80%, transparent);
  #         border: 0.5px solid color-mix(in srgb, var(--fg-color) 25%, transparent);
  #         padding: 12px; /* add uniform padding around the whole box */
  #       }

  #       /* ===== Input field ===== */
  #       text {
  #         font-size: 1.3rem;
  #         background: transparent;
  #         border: 1px solid var(--border-color);
  #         border-radius: 16px;
  #         margin-bottom: 12px;
  #         padding: 5px 10px;
  #         min-height: 44px;
  #         caret-color: var(--primary-color);
  #       }

  #       /* ===== List container ===== */
  #       .matches {
  #         background-color: transparent;
  #       }

  #       /* ===== Single match row ===== */
  #       .match {
  #         font-size: 1.1rem;
  #         padding: 4px 10px; /* tight vertical spacing */
  #         border-radius: 6px;
  #       }

  #       /* Remove default label margins */
  #       .match * {
  #         margin: 0;
  #         padding: 0;
  #         line-height: 1;
  #       }

  #       /* Selected / hover state */
  #       .match:selected,
  #       .match:hover {
  #         background-color: var(--selected-bg-color);
  #         color: var(--selected-fg-color);
  #       }

  #       .match:selected label.plugin.info,
  #       .match:hover label.plugin.info {
  #         color: var(--selected-fg-color);
  #       }

  #       .match:selected label.match.description,
  #       .match:hover label.match.description {
  #         color: color-mix(in srgb, var(--selected-fg-color) 90%, transparent);
  #       }

  #       /* ===== Plugin info label ===== */
  #       label.plugin.info {
  #         color: var(--fg-color);
  #         font-size: 1rem;
  #         min-width: 160px;
  #         text-align: left;
  #       }

  #       /* ===== Description label ===== */
  #       label.match.description {
  #         font-size: 0rem;
  #         color: var(--fg-color);
  #       }

  #       /* ===== Fade-in animation ===== */
  #       @keyframes fade {
  #         0% {
  #           opacity: 0;
  #         }
  #         100% {
  #           opacity: 1;
  #         }
  #       }
  #     '';
  #   };
  # };
}

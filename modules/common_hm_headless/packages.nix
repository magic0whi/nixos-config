{
  deploy-rs,
  pkgs,
  ...
}:
{
  # programs.yt-dlp.enable = !pkgs.stdenv.hostPlatform.isRiscV64;
  home.packages =
    with pkgs;
    [
      fastfetch
      bc
      ## Modern CLI Tools, replacement of grep/sed/...
      # A fast and polyglot tool for code searching, linting, rewriting at large scale
      # Supported languages: only some mainstream languages currently (don't support nix/nginx/yaml/toml/...)
      ast-grep
      sad # CLI search and replace, just like sed, but with diff preview.
      lazygit # Git terminal UI.
      hyperfine # Command-line benchmarking tool, replace `time`
      gping # ping, but with a graph (TUI)
      doggo # DNS client for humans
      duf # Disk Usage/Free Utility - a better 'df' alternative
      dust # A more intuitive version of `du` in rust
      ncdu # Analyzer your disk usage Interactively, via TUI (replacement of `du`)
      gdu # Disk usage analyzer(replacement of `du`)

      ## Nix related
      hydra-check # Check hydra (nix's build farm) for the build status of a package
      nix-index # A small utility to index nix store paths
      nix-init # Generate nix derivation from url
      nix-melt # A TUI flake.lock viewer, ref: https://github.com/nix-community/nix-melt

      keepassxc # Offline password manager, provides both CLI and GUI
      just # A command runner like make, but simpler

      # Misc
      # cowsay
      # gnumake

      # yq-go # yaml processor https://github.com/mikefarah/yq

      # caddy # A webserver with automatic HTTPS via Let's Encrypt (replacement of nginx)
      # croc # File transfer between computers securely and easily
      # wireguard-tools # manage wireguard vpn manually, via wg-quick
      # ventoy # create bootable usb

      # Dev-tools
      # NOTE: Please avoid to install language specific packages here (globally), instead, install them:
      # 1. per IDE, such as `programs.neovim.extraPackages`
      # 2. per-project, see https://github.com/the-nix-way/dev-templates

      # python313 # I use `nix develop github:magic0whi/dev_flake#python` instead
      # yarn # I use `nix develop github:magic0whi/dev_flake#node` instead
      # mitmproxy # HTTP/HTTPS proxy tool
      # DB related
      # mycli
      # pgcli
      # mongosh
      # sqlite

      ## FPGA
      # python312Packages.apycula # gowin fpga
      # yosys # FPGA synthesis
      # nextpnr # FPGA place and route
      # openfpgaloader # FPGA programming

      # AI Related
      # python313Packages.huggingface-hub # huggingface-cli

      # Misc
      # devbox
      # bfg-repo-cleaner # remove large files from git history
      # k6 # load testing tool
      # protobuf # protocol buffer compiler

      # TODO: Try it
      # Solve Coding Exercises - Learn By Doing
      # exercism

      # need to run `conda-install` before using it
      # need to run `conda-shell` before using command `conda`
      # conda is not available for MacOS
      # conda

      # android-tools
    ]
    # NOTE: Requires bootstrap GHC
    ++ lib.optionals (!stdenv.hostPlatform.isRiscV64) [
      nix-output-monitor # Command `nom`, works just like `nix` with more fancy output
      nix-tree # A TUI to visualize the dependency graph of a nix derivation, ref: https://github.com/utdemir/nix-tree
    ]
    ++ (
      if stdenv.hostPlatform.isRiscV64 then
        [ pkgs.pkgs.deploy-rs ]
      else
        [ deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.deploy-rs ]
    );
}

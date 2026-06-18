{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # tlrc # Official tldr written in Rust
    tealdeer # tldr written in Rust
    fd # Search for files by name, faster than `find`
    (ripgrep.override { withPCRE2 = true; }) # search for files by its content, replacement of `grep`
  ];
  # Environment variables that always set at login
  home.sessionVariables = {
    # Disable line-number since I use bat mostly and this will cause double line
    # numbering
    # LESS = "-R -N";
    LESS = "-R";
    LESSHISTFILE = config.xdg.cacheHome + "/less/history";
    LESSKEY = config.xdg.configHome + "/less/lesskey";
    WINEPREFIX = config.xdg.dataHome + "/wine";
    DELTA_PAGER = "less -R"; # Enable scrolling in git diff
  };
  home.shellAliases = lib.mkMerge [
    {
      k = "kubectl";
      urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
      urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";

      # `programs.eza.enable*Integration` overrides these
      ls = "eza";
      ll = "eza -lg";
      la = "eza -aa";
      lla = "eza -laag";
      # ls = "ls --color=auto -v";
      # ll = "ls -l --color=auto -v";
      # la = "ls -la --color=auto -v";
      # lh = "ls -lah --color=auto -v";

      grep = "grep --color=auto";
      ip = "ip --color=auto";
      cp = "cp -i";
      bc = "bc -lq"; # `-l` load ath lib, `-q` quiet
      cpr = "rsync --archive -hh --partial --info=stats1,progress2 --modify-window=1";
      mvr = "rsync --archive -hh --partial --info=stats1,progress2 --modify-window=1 --remove-source-files";
      diff = "diff --text --expand-tabs --unified --new-file --recursive --color=auto";
      # For `git filter-branch --help | bat -l man`, use
      # `MANWIDTH=999 git filter-branch --help | bat -lman` instead to prevent
      # git from baking ugly line breaks
      man = builtins.concatStringsSep " " [
        "MANPAGER=\"less -R --use-color -Dd+r -Du+b\"" # Set boldface -> red color, underline -> blue color
        "MANROFFOPT=\"-P-c\"" # Enables groff's "continuous" (non-paginated) output mode
        "MANWIDTH=$(($(tput cols) - 7))" # Adjustment manwidth when less' line number enabled
        "command man"
      ];
      tmux = "tmux -2"; # `-2` force assume the terminal supports 256 colors
      # Run `TERM=xterm-ghostty command ssh` if the remote machine has the corresponding terminfo installed
      ssh = "TERM=xterm-256color ssh";
      sshot = "ssh -o 'ConnectTimeout=10' -o 'IdentitiesOnly=no' -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no'"; # One-time SSH session
      sshstop = "ssh -O stop"; # Close a persistent SSH session

      status = "systemctl status";
      status-user = "systemctl --user status";
      show = "systemctl show";
      show-user = "systemctl --user show";
      is-active = "systemctl is-active";
      is-active-user = "systemctl --user is-active";
      start = "sudo systemctl start";
      start-user = "systemctl --user start";
      stop = "sudo systemctl stop";
      stop-user = "systemctl --user stop";
      restart = "sudo systemctl restart";
      restart-user = "systemctl --user restart";

      tarxz = "tar -I xz -cvf";
      tarxzls = "tar -I xz -tvf";
      tarzst = "tar -I 'zstd -T0' -cvf";
      tarzstls = "tar -I 'zstd -T0' -tvf";
      targz = "tar -I 'nix run nixpkgs#pigz --' -cvf";
      targzls = "tar -I 'nix run nixpkgs#pigz --' -tvf";
    }

    (lib.mkIf (!pkgs.stdenv.isDarwin) {
      Ci = "wl-copy";
      Co = "wl-paste";
      Coimg = "Co --type image";
    })
  ];

  catppuccin.fzf.enable = false; # catppuccin fzf is prone to fail on macOS
  programs = {
    zsh = {
      enable = true;
      # autosuggestion = {
      #   enable = true;
      #   highlight = "fg=60";
      #   strategy = [
      #     "match_prev_cmd"
      #     "history"
      #     "completion"
      #   ];
      # };
      initContent = lib.mkAfter ''
        export PATH="$PATH:${
          builtins.concatStringsSep ":" [
            "$HOME/.local/bin"
            "$HOME/go/bin"
            "$HOME/.cargo/bin"
          ]
        }"
      '';
    };
    # A modern replacement for `ls`, useful in bash/zsh prompt, but not in nushell
    eza = {
      enable = if pkgs.stdenv.hostPlatform.isRiscV64 then false else true;
      enableZshIntegration = false;
      git = true;
      icons = "auto";
    };
    # A `cat`-like with syntax highlighting and Git integration.
    bat = {
      enable = true;
      config.pager = "less -FR";
    };
    # A command-line fuzzy finder. Interactively filter its input using fuzzy searching, not limit to filenames.
    fzf = {
      enable = true;
      defaultOptions = [ "-m" ];
      defaultCommand = "rg --files"; # Using `ripgrep` in `fzf`
    };
    # zoxide is a smarter cd command, inspired by z and autojump.
    # It remembers which directories you use most frequently,
    # so you can "jump" to them in just a few keystrokes.
    # zoxide works on all major shells.
    #
    # z foo             # cd into highest ranked directory matching foo
    # z foo bar         # cd into highest ranked directory matching foo and bar
    # z foo /           # cd into a subdirectory starting with foo
    #
    # z ~/foo           # z also works like a regular cd command
    # z foo/            # cd into relative path
    # z ..              # cd one level up
    # z -               # cd into previous directory
    #
    # zi foo            # cd with interactive selection (using fzf)
    #
    # z foo<SPACE><TAB> # show interactive completions (zoxide v0.8.0+, bash 4.4+/fish/zsh only)
    zoxide.enable = true;

    # Atuin replaces your existing shell history with a SQLite database, and records additional context for your
    # commands. Additionally, it provides optional and fully encrypted synchronisation of your history between machines,
    # via an Atuin server.
    atuin = {
      enable = true;
      settings.sync_address = "https://atuin.${myvars.domain}";
    };
    starship = {
      enable = true;
      settings = {
        add_newline = false;
        line_break.disabled = true;
        status.disabled = false;
        character = {
          success_symbol = "[➜ ](bold green)";
          error_symbol = "[✗ ](bold red)";
        };
        aws = {
          disabled = true;
          symbol = "🅰 ";
        };
        gcloud = {
          disabled = true;
          # Do not show the account/project's info to avoid the leak of sensitive information when sharing the terminal
          format = ''on [$symbol$active(\($region\))]($style) '';
          symbol = "🅶 ️";
        };
        hostname = {
          ssh_only = false;
          format = "[$ssh_symbol$hostname]($style) ";
        };
        # Distracting when you need copy
        # time = {
        #   disabled = false;
        #   format = "[$time]($style)";
        # };
        right_format = "[$status$time]($style)";
        username = {
          format = "[$user]($style) @ ";
          show_always = true;
        };
      };
    };
    # tmux = {
    #   enable = true;
    #   keyMode = "vi";
    #   customPaneNavigationAndResize = true;
    #   shortcut = "a";
    #   terminal = "screen-256color";
    #   extraConfig = "set-option -g set-titles on";
    # };
  };
}

{
  config,
  const,
  lib,
  pkgs,
  ...
}:
{
  # For debug
  # xdg.configFile."helix/languages.toml".source =
  #   config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Works/test/helix_lanaguages.toml";

  programs.helix = {
    enable = true;
    # https://github.com/helix-editor/helix/issues/16431
    package = pkgs.helix.override {
      grammarOverlays = lib.singleton (
        _final: previous: {
          perl = previous.perl.overrideAttrs (_old: {
            version = "aa5600c8df1eb9ed111db72e20c741dd73ec336a";
            src = fetchTree {
              type = "github";
              owner = "tree-sitter-perl";
              repo = "tree-sitter-perl";
              rev = "aa5600c8df1eb9ed111db72e20c741dd73ec336a";
            };
          });
        }
      );
    };
    defaultEditor = true;
    settings = {
      # fallback to gruvbox
      theme = if config.catppuccin.enable then "catppuccin-${const.catppuccin.flavor}" else "gruvbox";
      editor = {
        bufferline = "multiple";
        color-modes = true;
        cursorline = true;
        line-number = "relative";
        rulers = [
          80
          120
        ];
        true-color = true;
        soft-wrap.enable = true;
        cursor-shape.insert = "bar";
        file-picker.hidden = false;
        indent-guides.render = true;
        statusline = {
          left = [
            "mode"
            "spinner"
            "file-name"
            "read-only-indicator"
            "file-modification-indicator"
          ];
          right = [
            "diagnostics"
            "version-control"
            "selections"
            "position"
            "file-encoding"
            "file-line-ending"
            "file-type"
          ];
        };
        whitespace.render = {
          space = "all";
          tab = "all";
          nbsp = "all";
          nnbsp = "all";
          newline = "none";
        };
      };
      keys = {
        insert."C-c" = "normal_mode";
        normal."C-r" = [
          ":config-reload"
          ":lsp-restart"
        ];
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "nixfmt";
            args = [ "--width=120" ];
          };
        }
        {
          name = "cpp";
          auto-format = true;
        }
        {
          name = "just";
          indent = {
            tab-width = 2;
            unit = "  ";
          };
        }
        {
          name = "latex";
          auto-format = true;
          formatter = {
            # command = "tex-fmt";
            # args = [ "--stdin" ];
            command = "latexindent";
            args = [ "-m" ];
          };
          language-servers = [
            "texlab"
            "ltex"
          ];
        }
        {
          name = "markdown";
          language-servers = [
            "marksman"
            "ltex"
            "lsp-ai"
          ];
        }
        {
          name = "json";
          auto-format = false;
        }
        {
          name = "kdl";
          indent = {
            tab-width = 2;
            unit = "  ";
          };
        }
      ];
      language-server = {
        yaml-language-server.config.yaml.format.singleQuote = true;
        # Typst live preview, open http://127.0.0.1:23635 in a browser
        # Ref: https://myriad-dreamin.github.io/tinymist/feature/preview.html#label-Running%20preview%20server%20in%20background%20(Since%20Tinymist%20v0.13.6)
        tinymist.config.preview.background = {
          enabled = true;
          args = [
            "--data-plane-host=127.0.0.1:23635"
            "--invert-colors=never"
          ];
        };
        beancount-language-server.config = {
          journal_file = "main.bean";
          completion.fuzzy_match_accounts = true;
          diagnosticFlags = [ "!" ]; # Surface incompleted transcation as warning
        };
        ltex = {
          command = "ltex-ls-plus";
          config.ltex = {
            # language = "zh-CN"; # default "en-US"
            hiddenFalsePositives.en-US = [
              ''{"rule": "UPPERCASE_SENTENCE_START", "sentence": "^[a-z][a-z0-9-_]+$"}''
            ];
            dictionary = fromTOML (builtins.readFile "${const.secretsDir}/ltex_dict.toml");
          };
        };
        texlab.config.texlab = {
          # formatterLineLength = 120;
          # latexFormatter = "tex-fmt"; # Use formatter on texlab causes lose cursor position
          # Lint
          chktex = {
            onOpenAndSave = true;
            onEdit = true;
          };
          forwardSearch =
            if pkgs.stdenv.hostPlatform.isDarwin then
              {
                # SyncTeX for Darwin/NixOS
                executable = "sioyek";
                args = [
                  "--reuse-window"
                  "--execute-command"
                  "toggle_synctex"
                  "--inverse-search"
                  ''texlab inverse-search -i "%%1" -l %%2''
                  "--forward-search-file"
                  "%f" # %f is the source file
                  "--forward-search-line"
                  "%l" # %l is the line number in the source file
                  "%p" # %p is the path to the generated PDF file
                ];
              }
            else
              {
                executable = "zathura";
                args = [
                  "--synctex-forward"
                  "%l:1:%f"
                  "%p"
                ];
              };
          build =
            let
              output_dir = "output";
            in
            {
              executable = "latexmk";
              args = [
                "-cd"
                "-pdflua"
                "-halt-on-error"
                "-interaction=nonstopmode"
                "-synctex=1"
                "-outdir=${output_dir}"
                "%f"
              ];
              auxDirectory = output_dir;
              logDirectory = output_dir;
              pdfDirectory = output_dir;
              # executable = "tectonic";
              # args = [
              #   "-X" # Use experimental V2 interface
              #   "compile"
              #   "%f"
              #   "--synctex"
              #   "--keep-logs"
              #   "--keep-intermediates"
              #   "--outdir=output"
              # ];
              onSave = true;
              forwardSearchAfter = true;
            };
        };
      };
    };
  };
}

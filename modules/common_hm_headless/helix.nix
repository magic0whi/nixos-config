{
  myvars,
  pkgs,
  ...
}:
{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    extraPackages =
      with pkgs;
      [
        bash-language-server
        vscode-json-languageserver
        yaml-language-server
        nixfmt-rs
        nixd
      ]
      ++ lib.optionals (!stdenv.hostPlatform.isRiscV64) [
        nil
        marksman
      ]; # NOTE: Requires bootstrap GHC
    settings = {
      # theme = "gruvbox"; # Disable if use catpuccin
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
          ];
        }
        {
          name = "json";
          auto-format = false;
        }
      ];
      language-server = {
        ltex = {
          command = "ltex-ls";
          config.ltex = {
            language = "en-US";
            dictionary = fromTOML (builtins.readFile "${myvars.secrets_dir}/ltex_dict.toml");
          };
        };
        texlab.config.texlab = {
          chktex = {
            onOpenAndSave = true;
            onEdit = true;
          };
          forwardSearch =
            if pkgs.stdenv.isDarwin then
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
          build = {
            executable = "latexmk";
            args = [
              "-cd"
              "-pdflua"
              "-halt-on-error"
              "-interaction=nonstopmode"
              "-synctex=1"
              "%f"
            ];
            onSave = true;
            forwardSearchAfter = true;
          };
        };
      };
    };
  };
}

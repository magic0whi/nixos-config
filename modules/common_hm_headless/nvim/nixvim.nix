# Ref
# - https://github.com/redyf/Neve
# - https://www.lazyvim.org/extras/lang/typst#typst-previewnvim
{
  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    # imports = [ Neve.nixvimModule ];
    # Plugins
    # bufferlines: Windows bar
    ## Completion
    # cmp
    # copilot
    # lspkind
    # dap: Debug Adapter Protocol
    # neo-tree: File tree

    # Library of 45+ independent Lua modules
    plugins = {
      mini = {
        enable = true;
        modules = {
          comment.options.custom_commentstring.__raw = ''
            function()
              return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
            end
          '';
          cursorword.opts.delay = 100;
        };
      };
      colorizer.enable = true; # Preview hex color
      nvim-autopairs.enable = true; # Auto-insert matching brackets
      nvim-surround.enable = true;
      persistence.enable = true; # Restore sessions, buffers, windows, and tabs between launches

      # Detect project roots and switch projects more intelligently
      project-nvim = {
        enable = true;
        enableTelescope = true;
      };
      tmux-navigator.enable = true; # Move between Neovim splits and tmux panes with the same keys
      todo-comments.enable = true; # Highlight and navigate TODO, FIXME, HACK, and similar annotations
      wakatime.enable = true; # Automatic coding activity tracking
      lspkind = {
        enable = true;
        settings = {
          maxwidth = 50;
          ellipsis_char = "...";
          symbolMap.Copilot = "";
        };
      };

      diffview.enable = true;

      # Snippets
      friendly-snippets.enable = true;
      luasnip = {
        enable = true;
        settings = {
          enable_autosnippets = true;
          store_selection_keys = "<Tab>";
        };
      };

      nui.enable = true; # UI component library
      # web-devicons.enable = true; # Nerd Font icons
    };
  };
}

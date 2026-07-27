{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [ pkgs.vimPlugins.nvterm ];

    extraConfigLua = ''
      require("nvterm").setup({
        terminals = {
          shell = vim.o.shell,
          type_opts = {
            float = {
              relative = "editor",
              row = 0.3,
              col = 0.25,
              width = 0.5,
              height = 0.4,
              border = "single",
            },
            horizontal = { location = "rightbelow", split_ratio = 0.5 },
            vertical = { location = "rightbelow", split_ratio = 0.5 },
          },
        },
        behavior = {
          autoclose_on_quit = { enabled = false, confirm = true },
          close_on_exit = true,
          auto_insert = true,
        },
      })
    '';

    keymaps = [
      {
        mode = [
          "n"
          "t"
        ];
        key = "<A-h>";
        action.__raw = ''function() require("nvterm.terminal").toggle("horizontal") end'';
        options = {
          silent = true;
          desc = "Toggle horizontal terminal";
        };
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<A-v>";
        action.__raw = ''function() require("nvterm.terminal").toggle("vertical") end'';
        options = {
          silent = true;
          desc = "Toggle vertical terminal";
        };
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<A-i>";
        action.__raw = ''function() require("nvterm.terminal").toggle("float") end'';
        options = {
          silent = true;
          desc = "Toggle floating terminal";
        };
      }
    ];
  };
}

{ lib, ... }:
{
  programs.nixvim = {
    plugins.markdown-preview = {
      enable = true;
      settings = {
        browser = "firefox";
        theme = "dark";
      };
    };
    keymaps = lib.singleton {
      mode = "n";
      key = "<leader>cp";
      action = "<cmd>MarkdownPreview<cr>";
      options.desc = "Markdown Preview";
    };
  };
}

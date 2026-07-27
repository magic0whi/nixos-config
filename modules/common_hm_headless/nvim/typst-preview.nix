{ lib, ... }:
{
  programs.nixvim = {
    plugins.lazy.plugins = lib.singleton {
      __unkeyed-1 = "chomosuke/typst-preview.nvim";
      ft = "typst";
      cmd = [
        "TypstPreview"
        "TypstPreviewToggle"
        "TypstPreviewFollowCursor"
        "TypstPreviewNoFollowCursor"
        "TypstPreviewSyncCursor"
      ];
      opts.dependencies_bin.tinymist = "tinymist";
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>vp";
        action = "<cmd>TypstPreviewToggle<CR>";
        options.desc = "Toggle Typst Preview";
      }
      {
        mode = "n";
        key = "<leader>vs";
        action = "<cmd>TypstPreviewSyncCursor<CR>";
        options.desc = "Sync Typst Preview to Cursor";
      }
      {
        mode = "n";
        key = "<leader>vf";
        action = "<cmd>TypstPreviewFollowCursorToggle<CR>";
        options.desc = "Toggle Follow Cursor";
      }
    ];
  };
}

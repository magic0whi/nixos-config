{ lib, ... }:
{
  programs.nixvim = {
    plugins.lazygit.enable = true;

    extraConfigLua = ''
      require("telescope").load_extension("lazygit")
    '';

    keymaps = lib.singleton {
      mode = "n";
      key = "<leader>gg";
      action = "<cmd>LazyGit<CR>";
      options.desc = "LazyGit (root dir)";
    };
  };
}

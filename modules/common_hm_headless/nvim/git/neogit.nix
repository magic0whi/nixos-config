{ lib, ... }:
{
  programs.nixvim = {
    plugins.neogit.enable = false;
    keymaps = lib.singleton {
      mode = "n";
      key = "<leader>gg";
      action = "<cmd>Neogit<CR>";
    };
  };
}

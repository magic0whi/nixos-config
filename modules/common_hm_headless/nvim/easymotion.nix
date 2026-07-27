{ pkgs, ... }:
{
  programs.nixvim = {
    globals = {
      EasyMotion_do_mapping = 0; # Disable default mappings
      EasyMotion_smartcase = 1; # Turn on case-insensitive feature
      EasyMotion_startofline = 0; # keep cursor column when JK motion
    };
    extraPlugins = [ pkgs.vimPlugins.vim-easymotion ];
    keymaps = [
      {
        mode = [ "n" ];
        key = "ga";
        # overwin motions move across windows
        action = "<Plug>(easymotion-overwin-w)";
      }
      {
        mode = [ "n" ];
        key = "gj";
        action = "<Plug>(easymotion-j)";
      }
      {
        mode = [ "n" ];
        key = "gk";
        action = "<Plug>(easymotion-k)";
      }
    ];
  };
}

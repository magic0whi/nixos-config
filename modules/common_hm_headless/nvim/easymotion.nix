{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [ pkgs.vimPlugins.vim-easymotion ];
    extraConfigVim = ''
      let g:EasyMotion_do_mapping = 0 " Disable default mappings
      let g:EasyMotion_smartcase = 1  " Turn on case-insensitive feature
    '';
    keymaps = [
      {
        mode = [ "n" ];
        key = "<leader>gw";
        # overwin motions move across windows
        action = "<Plug>(easymotion-overwin-f2)";
      }
      {
        mode = [ "n" ];
        key = "<leader>j";
        action = "<Plug>(easymotion-j)";
      }
      {
        mode = [ "n" ];
        key = "<leader>k";
        action = "<Plug>(easymotion-k)";
      }
    ];
  };
}

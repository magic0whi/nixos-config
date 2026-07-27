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
    plugins.mini = {
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
  };
}

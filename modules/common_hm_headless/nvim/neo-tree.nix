{
  programs.nixvim = {
    plugins.neo-tree = {
      enable = true;
      settings = {
        popup_border_style = "rounded"; # Type: null or one of “NC”, “double”, “none”, “rounded”, “shadow”, “single”, “solid” or raw lua code
        enable_refresh_on_write = true;
        enable_modified_markers = true;
        enable_git_status = true;
        enable_diagnostics = true;
        close_if_last_window = true;
        buffers = {
          bind_to_cwd = false;
          follow_current_file.enabled = true;
        };
        window = {
          width = 40;
          height = 15;
          auto_expand_width = false;
        };
      };
    };

    # keymaps = [
    #   {
    #     mode = "n";
    #     key = "<leader>e";
    #     action = ":Neotree toggle reveal_force_cwd<cr>";
    #     options = {
    #       silent = true;
    #       desc = "Explorer NeoTree (root dir)";
    #     };
    #   }
    #   {
    #     mode = "n";
    #     key = "<leader>E";
    #     action = "<cmd>Neotree toggle<CR>";
    #     options = {
    #       silent = true;
    #       desc = "Explorer NeoTree (cwd)";
    #     };
    #   }
    #   {
    #     mode = "n";
    #     key = "<leader>be";
    #     action = ":Neotree buffers<CR>";
    #     options = {
    #       silent = true;
    #       desc = "Buffer explorer";
    #     };
    #   }
    #   {
    #     mode = "n";
    #     key = "<leader>ge";
    #     action = ":Neotree git_status<CR>";
    #     options = {
    #       silent = true;
    #       desc = "Git explorer";
    #     };
    #   }
    # ];
  };
}

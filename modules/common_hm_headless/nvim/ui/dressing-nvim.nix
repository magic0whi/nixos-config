# Better input/select dialogs
{
  programs.nixvim.plugins.dressing = {
    enable = true;
    settings = {
      input = {
        enabled = true;
        default_prompt = "Input";
        trim_prompt = true;
        title_pos = "left";
        insert_only = true;
        start_in_insert = true;
        border = "rounded";
        relative = "cursor";
        prefer_width = 40;
        width = null;
        max_width = [
          140
          0.9
        ];
        min_width = [
          20
          0.2
        ];
        win_options = {
          wrap = false;
          list = true;
          listchars = ''precedes:\226\128\166,extends:\226\128\166'';
          sidescrolloff = 0;
        };
        mappings = {
          n = {
            "<Esc>" = "Close";
            "<CR>" = "Confirm";
          };
          i = {
            "<C-c>" = "Close";
            "<CR>" = "Confirm";
            "<Up>" = "HistoryPrev";
            "<Down>" = "HistoryNext";
          };
        };
      };
      select = {
        enabled = true;
        backend = [
          "telescope"
          "fzf_lua"
          "fzf"
          "builtin"
          "nui"
        ];
        trim_prompt = true;
        telescope = null;
        fzf = {
          window = {
            width = 0.5;
            height = 0.4;
          };
        };
        nui = {
          position = "50%";
          size = null;
          relative = "editor";
          border = {
            style = "rounded";
          };
          max_width = 80;
          max_height = 40;
          min_width = 40;
          min_height = 10;
        };
        builtin = {
          show_numbers = true;
          border = "rounded";
          relative = "editor";
          win_options = {
            cursorline = true;
            cursorlineopt = "both";
          };
          width = null;
          max_width = [
            140
            0.8
          ];
          min_width = [
            40
            0.2
          ];
          height = null;
          max_height = 0.9;
          min_height = [
            10
            0.2
          ];
          mappings = {
            "<Esc>" = "Close";
            "<C-c>" = "Close";
            "<CR>" = "Confirm";
          };
        };
      };
    };
  };
}

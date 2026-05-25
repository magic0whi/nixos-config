{
  myvars,
  pkgs,
  lib,
  ...
}:
{
  # This value determines the Home Manager release that your configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards incompatible changes.
  #
  # You can update Home Manager without changing this value. See the Home Manager release notes for a list of state
  # version changes in each release.
  home.stateVersion = myvars.nixos_state_version;
  programs.home-manager.enable = true; # Let Home Manager install and manage itself.
  ## BEGIN pip.nix
  # Use mirror for pip install
  xdg.configFile."pip/pip.conf".text = ''
    [global]
    index-url = https://mirror.nju.edu.cn/pypi/web/simple
    format = columns
  '';
  ## END pip.nix
  ## BEGIN btop.nix
  # Alternative to htop/nmon
  programs.btop = {
    enable = true;
    settings.theme_background = false; # Make btop transparent
  };
  ## END btop.nix
  ## BEGIN yazi.nix
  # Terminal file manager
  programs.yazi = {
    # NOTE: Home Manager provides `y` to allow changing working directory when exitig Yazi
    enable = true;
    settings.mgr = {
      linemode = "mtime";
      show_hidden = true;
      sort_dir_first = true;
    };
    plugins.drag = pkgs.yaziPlugins.drag;
    plugins.recycle-bin = if pkgs.stdenv.isDarwin then pkgs.emptyFile else pkgs.yaziPlugins.recycle-bin;
    initLua = if pkgs.stdenv.isDarwin then null else ''require("recycle-bin"):setup()'';
    extraPackages = with pkgs; [
      ripdrag
      trash-cli
      ueberzugpp
    ];
    keymap = {
      mgr.prepend_keymap = [
        {
          on = [ "<C-s>" ];
          run = "plugin drag";
          desc = "Drag Files";
        }
        {
          on = [
            "R"
            "b"
          ];
          run = "plugin recycle-bin";
          desc = "Open Trash";
        }
        {
          on = [
            "g"
            "w"
          ];
          run = "cd ~/Works";
          desc = "Go ~/Works";
        }
        {
          on = [
            "g"
            "a"
          ];
          run = "cd ~/Works/AI/ai_instructions";
          desc = "~/Works/AI/ai_instructions";
        }
      ];
    };
  };
  ## END yazi.nix

  ## BEGIN direnv.nix
  # programs.direnv = {
  #   enable = true;
  #   nix-direnv.enable = true;
  # };
  ## END direnv.nix

  ## BEGIN neovim.nix
  # programs.neovim = {
  #   enable = true;
  #   viAlias = true;
  #   vimAlias = true;
  # };
  ## END neovim.nix

  ## BEGIN catppuccin.nix
  catppuccin = {
    # Enable Catppuccin globally
    enable = lib.mkDefault true;
    accent = myvars.catppuccin_accent;
    flavor = myvars.catppuccin_flavor;
  };
  ## END catppuccin.nix
}

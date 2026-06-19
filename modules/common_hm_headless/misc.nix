{
  const,
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
  home.stateVersion = const.nixosStateVersion;
  programs.home-manager.enable = true; # Let Home Manager install and manage itself.
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
  ## BEGIN catppuccin.nix
  catppuccin = {
    autoEnable = true; # Whether to enable all Catppuccin integrations by default
    enable = lib.mkDefault true;
    inherit (const.catppuccin) accent flavor;
  };
  ## END catppuccin.nix
}

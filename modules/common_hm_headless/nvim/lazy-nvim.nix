{ config, lib, ... }:
{
  programs.nixvim = {
    extraConfigLuaPost = ''
      vim.go.loadplugins = true
    '';
    plugins.lazy = {
      enable = true;
      # Keep settings.spec non-empty so lazy.nvim treats settings as opts,
      # while still sourcing neocord through Nixvim's managed plugin option.
      plugins = lib.singleton {
        pkg = config.programs.nixvim.plugins.neocord.package;
        name = "neocord";
        config = "";
      };
      settings = {
        dev.fallback = lib.mkForce true; # Download plugins if not in nix store
        performance = {
          reset_packpath = false; # Nixvim manages plugins via packpath; lazy.nvim must not reset it
          rtp.reset = false;
        };
      };
    };
  };
}

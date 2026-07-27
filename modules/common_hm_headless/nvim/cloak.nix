# Hide in file secrets, such as API keys, tokens, or env values while editing
{ lib, ... }:
{
  programs.nixvim.plugins.cloak = {
    enable = true;
    settings = {
      cloak_character = "*";
      highlight_group = "Comment";
      patterns = lib.singleton {
        file_pattern = [
          ".env*"
          "wrangler.toml"
          ".dev.vars"
        ];
        cloak_pattern = "=.+";
      };
    };
  };
}

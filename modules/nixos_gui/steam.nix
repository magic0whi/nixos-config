{
  config,
  pkgs,
  ...
}:
{
  programs.steam = {
    enable = pkgs.stdenv.isx86_64;
    # This also enables programs.gamescope.enable
    gamescopeSession.enable = config.programs.steam.enable;
    # Packages only available to Steam
    # Use `steam-run` to run Steam FHS, e.g. `steam-run gamescope`
    extraPackages = with pkgs; [ gamescope ];
  };
}

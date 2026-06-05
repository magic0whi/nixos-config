{
  pkgs,
  ...
}:
{
  programs.steam = {
    enable = true;
    # This also enables programs.gamescope.enable
    gamescopeSession.enable = true;
    # Packages only available to Steam
    # Use `steam-run` to run Steam FHS, e.g. `steam-run gamescope`
    extraPackages = with pkgs; [ gamescope ];
  };
}

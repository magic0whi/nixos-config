{
  # config,
  lib,
  pkgs,
  ...
}:
{
  ## BEGIN xdg.nix
  xdg.enable = true; # Enable management of XDG base directories on macOS
  ## END xdg.nix
  ## BEGIN shell.nix
  home.shellAliases = {
    Ci = "pbcopy";
    Co = "pbpaste";
  };
  ## END shell.nix
  ## BEGIN associations.nix
  home.activation.mpv_associations =
    let
      duti_exe = lib.getExe' pkgs.duti "duti";
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Set UTIs
      ${duti_exe} -s io.mpv public.movie viewer
      # Set file extensions
      ${duti_exe} -s io.mpv .mkv viewer
      ${duti_exe} -s io.mpv .mp4 viewer
      ${duti_exe} -s com.google.Chrome .webm viewer
      ${duti_exe} -s com.apple.Preview .heic viewer
    '';
  ## END associations.nix
}

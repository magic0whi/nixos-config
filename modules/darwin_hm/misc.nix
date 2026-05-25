{
  config,
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
  ## BEGIN gpg.nix
  # NOTE: Don't bootout the 'system/com.openssh.ssh-agent', as it seizes the '$SSH_AUTH_SOCK'
  home.sessionVariablesExtra = ''
    export SSH_AUTH_SOCK="$(${config.programs.gpg.package}/bin/gpgconf --list-dirs agent-ssh-socket)"
  '';
  # launchd.agents.gpg-agent.config = { # Enable logs for debugging
  #   StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/gnupg-agent.stderr.log";
  #   StandardOutPath = "${config.home.homeDirectory}/Library/Logs/gnupg-agent.stdout.log";
  # };
  ## END gpg.nix
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

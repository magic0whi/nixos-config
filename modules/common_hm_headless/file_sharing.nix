{ xdgRel, ... }:
{
  programs.rclone.enable = true;
  home.persistence."/persistent".directories = [ "${xdgRel.configHome}/rclone" ];
}

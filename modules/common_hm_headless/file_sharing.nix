{
  programs.rclone.enable = true;
  home.persistence."/persistent".directories = [ ".config/rclone" ];
}

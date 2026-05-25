{ config, ... }:
{
  sops.gnupg.home = config.programs.gpg.homedir;
  # sops.age = {
  #   sshKeyPaths = ["proteus@recovery.ssh.priv.key"];
  #   keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
  #   generateKey = true;
  # };
}

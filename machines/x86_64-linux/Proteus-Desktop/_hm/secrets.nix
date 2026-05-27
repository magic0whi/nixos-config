{ config, ... }:
{
  sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/ssh_host_ed25519_key" ];
}

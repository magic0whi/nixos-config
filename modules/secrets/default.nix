{ myvars, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.sops ];
  sops.defaultSopsFile = "${myvars.secretsDir}/common.sops.yaml";
  # sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}

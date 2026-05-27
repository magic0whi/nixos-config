{ myvars, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.sops ];
  sops.defaultSopsFile = "${myvars.secrets_dir}/common.sops.yaml";
  # sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}

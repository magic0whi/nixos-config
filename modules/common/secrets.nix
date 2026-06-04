{
  config,
  myvars,
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.sops ];
  sops.defaultSopsFile = "${myvars.secretsDir}/common.sops.yaml";
  # sops-nix starts very early (before impermanence mount)
  sops.age.sshKeyPaths =
    if (config.environment ? persistence && config.environment.persistence != { }) then
      [ "/persistent/etc/ssh/ssh_host_ed25519_key" ]
    else
      [ "/etc/ssh/ssh_host_ed25519_key" ];
}

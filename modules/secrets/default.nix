{
  config,
  myvars,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.sops]; # For debugging
  sops.defaultSopsFile = "${myvars.secrets_dir}/common.sops.yaml";
  sops.age.sshKeyPaths =
    if (config.environment ? persistence && config.environment.persistence != {})
    then ["/persistent/etc/ssh/ssh_host_ed25519_key"]
    else ["/etc/ssh/ssh_host_ed25519_key"];
}

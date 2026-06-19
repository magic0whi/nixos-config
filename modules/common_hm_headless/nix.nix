{
  config,
  const,
  ...
}:
{
  xdg.configFile."nix/public.key".source = "${const.secretsDir}/nix_public.key";
  sops = {
    secrets = {
      "nix_secret.key" = {
        sopsFile = "${const.secretsDir}/nix_secret.key.sops";
        format = "binary";
        path = "${config.xdg.configHome}/nix/secret.key";
      };
      aws_access_key.sopsFile = "${const.secretsDir}/common_hm.sops.yaml";
      aws_secret_key.sopsFile = "${const.secretsDir}/common_hm.sops.yaml";
    };
    templates."aws_credentials" = {
      content = ''
        [nixbuilder]
        aws_access_key_id=${config.sops.placeholder.aws_access_key}
        aws_secret_access_key=${config.sops.placeholder.aws_secret_key}
      '';
      path = "${config.home.homeDirectory}/.aws/credentials";
    };
  };
}

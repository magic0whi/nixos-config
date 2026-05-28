{
  config,
  myvars,
  ...
}:
{
  xdg.configFile."nix/public.key".source = "${myvars.secretsDir}/nix_public.key";
  sops = {
    secrets = {
      "nix_secret.key" = {
        sopsFile = "${myvars.secretsDir}/nix_secret.key.sops";
        format = "binary";
        path = "${config.xdg.configHome}/nix/secret.key";
      };
      aws_secret_access_key.sopsFile = "${myvars.secretsDir}/common_hm.sops.yaml";
    };
    templates."aws_credentials" = {
      content = ''
        [nixbuilder]
        aws_access_key_id=nixbuilder
        aws_secret_access_key=${config.sops.placeholder.aws_secret_access_key}
      '';
      path = "${config.home.homeDirectory}/.aws/credentials";
    };
  };
}

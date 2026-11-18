{
  config,
  const,
  mylib,
  xdgRel,
  ...
}:
{
  # Keep flake input caches
  home.persistence."/persistent".directories = [ "${xdgRel.cacheHome}/nix" ];

  xdg.configFile."nix/public.key".text = const.nixCache.publicKey;
  sops = {
    secrets =
      let
        sopsFile = "${const.secretsDir}/${const.networking.findFirstHostBySubdomain "niks3"}_shared.sops.yaml";
      in
      {
        github_access_tokens = { };
        "nix_secret.key" = {
          sopsFile = "${const.secretsDir}/nix_secret.key.sops";
          format = "binary";
          path = "${config.xdg.configHome}/nix/secret.key";
        };
        nix-cache_access_key = { inherit sopsFile; };
        nix-cache_secret_key = { inherit sopsFile; };
      };
    templates = {
      aws_credentials = {
        path = "${config.home.homeDirectory}/.aws/credentials";
        content = mylib.toINI {
          nixbuilder = {
            aws_access_key_id = config.sops.placeholder.nix-cache_access_key;
            aws_secret_access_key = config.sops.placeholder.nix-cache_secret_key;
          };
        };
      };
      "nix-access-tokens.conf".content = mylib.toConf {
        access-tokens = "github.com=${config.sops.placeholder.github_access_tokens}";
      };
    };
  };
  nix.extraOptions = ''
    !include ${config.sops.templates."nix-access-tokens.conf".path}
  '';
}

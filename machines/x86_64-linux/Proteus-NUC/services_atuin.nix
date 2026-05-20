{
  config,
  myvars,
  ...
}: {
  sops = let
    restartUnits = ["atuin.service"];
  in {
    secrets.atuin_db_password = {
      inherit restartUnits;
      sopsFile = "${myvars.secrets_dir}/${config.networking.hostName}.sops.yaml";
    };
    templates."atuin.env" = {
      inherit restartUnits;
      # Atuin doesn't allow empty host, add a bogus host "114514"
      content = "ATUIN_DB_URI='postgres://atuin:${
        config.sops.placeholder.atuin_db_password
      }@114514/?host=/run/postgresql'";
      # content = "ATUIN_DB_URI='postgres://atuin:${
      #   config.sops.placeholder.atuin_db_password
      # }@postgresql.${myvars.domain}/atuin?sslmode=require'";
    };
  };
  services.atuin = {
    enable = true;
    environmentFile = config.sops.templates."atuin.env".path;
    openRegistration = true;
  };
}

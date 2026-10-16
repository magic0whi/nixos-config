{
  config,
  const,
  lib,
  pkgs,
  mylib,
  ...
}:
{
  sops = {
    secrets = lib.mkMerge (
      map
        (
          num:
          let
            sopsFile = "${const.secretsDir}/common_hm.sops.yaml";
          in
          {
            "project-${num}.secret.json" = {
              sopsFile = "${const.secretsDir}/gcloud_project-${num}.secret.json.sops";
              format = "binary";
              path = "${config.xdg.configHome}/gcloud/project-${num}.secret.json";
            };
            "config_account_project-${num}" = { inherit sopsFile; };
            "config_projectid_project-${num}" = { inherit sopsFile; };
          }
        )
        [
          "0"
          "1"
          "2"
        ]
    );
    templates = lib.mkMerge (
      map
        (num: {
          "config_project-${num}" = {
            path = "${config.xdg.configHome}/gcloud/configurations/config_project-${num}";
            content = mylib.toINI {
              core = {
                account = config.sops.placeholder."config_account_project-${num}";
                project = config.sops.placeholder."config_projectid_project-${num}";
              };
            };
          };
        })
        [
          "0"
          "1"
          "2"
        ]
    );
  };
  home.packages = with pkgs; [
    google-cloud-sdk # gcloud
    terraform
    terraformer
    terraform-ls # LSP
  ];
}

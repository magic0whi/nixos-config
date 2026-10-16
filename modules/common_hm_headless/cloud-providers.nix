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
            oracle_user_ocid = { inherit sopsFile; };
            oracle_fingerprint = { inherit sopsFile; };
            oracle_tenancy = { inherit sopsFile; };
            oracle_region = { inherit sopsFile; };
            "oracle_secret.pem" = {
              sopsFile = "${const.secretsDir}/oracle_secret.pem.sops";
              format = "binary";
            };
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
      ++ [
        {
          ".oci/config" = {
            path = "${config.home.homeDirectory}/.oci/config";
            content = mylib.toINI {
              DEFAULT = {
                user = config.sops.placeholder.oracle_user_ocid;
                fingerprint = config.sops.placeholder.oracle_fingerprint;
                tenancy = config.sops.placeholder.oracle_tenancy;
                region = config.sops.placeholder.oracle_region;
                key_file = config.sops.secrets."oracle_secret.pem".path;
              };
            };
          };
        }
      ]
    );
  };
  home = {
    sessionVariables.OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING = "True";
    packages = with pkgs; [
      google-cloud-sdk # gcloud
      terraform
      terraformer
      terraform-ls # LSP
      oci-cli
    ];
  };
}

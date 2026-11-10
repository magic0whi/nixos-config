{
  config,
  const,
  lib,
  pkgs,
  mylib,
  ...
}:
let
  projects = [
    "0"
    "1"
    "2"
    "4"
  ];
in
{
  sops = {
    secrets = lib.mkMerge (
      map (num: {
        "project-${num}.secret.json" = {
          sopsFile = "${const.secretsDir}/gcloud_project-${num}.secret.json.sops";
          format = "binary";
          path = "${config.xdg.configHome}/gcloud/project-${num}.secret.json";
        };
        "config_account_project-${num}" = { };
        "config_projectid_project-${num}" = { };
        oracle_user_ocid = { };
        oracle_fingerprint = { };
        oracle_tenancy = { };
        oracle_region = { };
        "oracle_secret.pem" = {
          sopsFile = "${const.secretsDir}/oracle_secret.pem.sops";
          format = "binary";
        };
      }) projects
    );
    templates = lib.mkMerge (
      map (num: {
        "config_project-${num}" = {
          path = "${config.xdg.configHome}/gcloud/configurations/config_project-${num}";
          content = mylib.toINI {
            core = {
              account = config.sops.placeholder."config_account_project-${num}";
              project = config.sops.placeholder."config_projectid_project-${num}";
            };
          };
        };
      }) projects
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
    persistence."/persistent".directories = [
      ".config/gcloud"
      ".config/terraform.d"
      # TODO: Try pulumi an open source infrastructure-as-code alternative to terraform
      {
        directory = ".pulumi";
        mode = "0700";
      }
      {
        directory = ".aws";
        mode = "0700";
      }
      {
        directory = ".docker";
        mode = "0700";
      }
      {
        directory = ".kube";
        mode = "0700";
      }
    ];
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

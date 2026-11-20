{
  mySecrets,
  config,
  lib,
  mylib,
  pkgs,
  xdgRel,
  ...
}:
let
  gcloud_sops_file = mySecrets + "/cloud-providers/gcloud.sops.yaml";
  oracle_sops_file = mySecrets + "/cloud-providers/oracle.sops.yaml";
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
      (map (num: {
        "gcloud_project-${num}_secret" = {
          sopsFile = mySecrets + "/cloud-providers/gcloud_project-${num}.secret.json.sops";
          format = "binary";
          path = config.xdg.configHome + "/gcloud/project-${num}.secret.json";
        };
        "gcloud_project-${num}_config_account".sopsFile = gcloud_sops_file;
        "gcloud_project-${num}_config_projectid".sopsFile = gcloud_sops_file;
      }) projects)
      ++ lib.singleton {
        oracle_user_ocid.sopsFile = oracle_sops_file;
        oracle_fingerprint.sopsFile = oracle_sops_file;
        oracle_tenancy.sopsFile = oracle_sops_file;
        oracle_region.sopsFile = oracle_sops_file;

        "oracle_secret.pem" = {
          sopsFile = mySecrets + "/cloud-providers/oracle_secret.pem.sops";
          format = "binary";
        };
      }
    );
    templates = lib.mkMerge (
      map (num: {
        "gcloud_project-${num}_config" = {
          path = config.xdg.configHome + "/gcloud/configurations/config_project-${num}";
          content = mylib.toINI {
            core = {
              account = config.sops.placeholder."gcloud_project-${num}_config_account";
              project = config.sops.placeholder."gcloud_project-${num}_config_projectid";
            };
          };
        };
      }) projects
      ++ lib.singleton {
        ".oci/config" = {
          path = config.home.homeDirectory + "/.oci/config";
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
    );
  };
  home = {
    persistence."/persistent".directories = [
      "${xdgRel.configHome}/gcloud"
      "${xdgRel.configHome}/terraform.d"
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

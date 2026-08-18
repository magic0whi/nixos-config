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
  # Add plugin terraform-provider-google for `terraformer`
  home.file =
    let
      arch = "${pkgs.go.GOOS}_${pkgs.go.GOARCH}";
      version = "7.31.0";
      provider = pkgs.terraform-providers.hashicorp_google.overrideAttrs (_: {
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "hashicorp";
          repo = "terraform-provider-google";
          rev = "v${version}";
          hash = "sha256-6cvRvVQmKRi4kyNAo/UAGN00bO+uCJYvf661xYW/QCQ=";
        };
        vendorHash = "sha256-UoS4iIVHhCQ+Zk+SJmsMHJgJBKLMbfMVmtm4MDmzT68=";
        postInstall = ''
          dir=$out/libexec/terraform-providers/registry.terraform.io/hashicorp/google/${version}/''${GOOS}_''${GOARCH}
          mkdir -p "$dir"
          mv $out/bin/* "$dir/terraform-provider-google_${version}"
          rmdir $out/bin
        '';
      });
    in
    {
      ".terraform.d/plugins/${arch}/terraform-provider-google_v${version}".source =
        "${provider}/libexec/terraform-providers/registry.terraform.io/hashicorp/google/${version}/${arch}/terraform-provider-google_${version}";
    };
}

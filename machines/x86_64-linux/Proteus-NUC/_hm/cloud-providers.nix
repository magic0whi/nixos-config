{
  config,
  const,
  pkgs,
  ...
}:
{
  sops.secrets = {
    "project-0.secret.json" = {
      sopsFile = "${const.secretsDir}/gcloud_project-0.secret.json.sops";
      format = "binary";
      path = "${config.xdg.configHome}/gcloud/project-0.secret.json";
    };
    "project-1.secret.json" = {
      sopsFile = "${const.secretsDir}/gcloud_project-1.secret.json.sops";
      format = "binary";
      path = "${config.xdg.configHome}/gcloud/project-1.secret.json";
    };
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
      arch = "linux_amd64";
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

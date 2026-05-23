{
  config,
  mylib,
  myvars,
  pkgs,
  ...
}: {
  imports = mylib.scan_path ./.;
  ## BEGIN packages.nix
  home.packages = with pkgs; [
    (nvtopPackages.intel.override {nvidia = true;})
    minicom # embedded development
    chezmoi
    libreoffice
    qpdf
    act # Run your GitHub Actions locally
    gemini-cli
    google-cloud-sdk # gcloud
    terraform
    terraformer
    terraform-ls # LSP
    witr
  ];
  ## END packages.nix
  ## BEGIN cloud-providers.nix
  sops.secrets = {
    "project-0.secret.json" = {
      sopsFile = "${myvars.secrets_dir}/gcloud_project-0.secret.json.sops";
      format = "binary";
      path = "${config.xdg.configHome}/gcloud/project-0.secret.json";
    };
    "project-1.secret.json" = {
      sopsFile = "${myvars.secrets_dir}/gcloud_project-1.secret.json.sops";
      format = "binary";
      path = "${config.xdg.configHome}/gcloud/project-1.secret.json";
    };
  };
  # Add plugin terraform-provider-google for `terraformer`
  home.file = let
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
  in {
    ".terraform.d/plugins/${arch}/terraform-provider-google_v${version}".source = "${provider}/libexec/terraform-providers/registry.terraform.io/hashicorp/google/${version}/${arch}/terraform-provider-google_${version}";
  };
  ## END cloud-providers.nix
  # programs.ssh = {
  #   enable = true;
  #   enableDefaultConfig = false;
  #   matchBlocks = {
  #     "*" = { # Default values
  #       # A private key that is used during authentication will be added to ssh-agent if it is running
  #       addKeysToAgent = "yes";
  #       # Allow to securely use local SSH agent to authenticate on the remote machine. It has the same effect as adding
  #       # CLI option `ssh -A user@host`
  #       forwardAgent = true;
  #     };
  #     "ssh.github.com hf.co" = lib.hm.dag.entryBefore ["*.tailba6c3f.ts.net"] {
  #       user = "git";
  #       identityFile = "~/sync_work/keys/private/proteus_ed25519.key";
  #       identitiesOnly = true; # Prevent sending default identity files first.
  #     };
  #     "192.168.*" = {
  #       identityFile = "/etc/agenix/ssh-key-romantic"; # romantic holds my homelab~
  #       # Specifies that ssh should only use the identity file. Required to prevent sending default identity files
  #       # first.
  #       identitiesOnly = true;
  #     };
  #   };
  # };
  # modules.editors.emacs.enable = true;
  ## BEGIN misc.nix
  programs.mpv.profiles.common.vulkan-device =
    if config.wayland.windowManager.hyprland.nvidia_sync
    then "NVIDIA GeForce RTX 3070 Laptop GPU"
    else "Intel(R) UHD Graphics (TGL GT1)";
  ## END misc.nix
}

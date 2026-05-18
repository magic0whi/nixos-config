{
  config,
  lib,
  mylib,
  myvars,
  pkgs,
  ...
}: let
  dpi_scale = lib.substring 0 4 (lib.strings.floatToString 1.25);
  # Ref: https://wiki.hyprland.org/Configuring/Monitors/
  # TIP: ls /sys/class/drm/card*
  # 10-bit will cause the internal monitor flickering when using PRIME Sync
  main_monitor =
    if config.wayland.windowManager.hyprland.nvidia
    then "eDP-1,highres,auto,${dpi_scale},bitdepth,8,cm,adobe"
    else "eDP-1,highres,auto,${dpi_scale},bitdepth,10,cm,adobe";
  secondary_monitor = "HDMI-A-1,highres,auto-left,2,bitdepth,10,cm,adobe";
  third_monitor = "DP-3,highres,auto-up,1.67,bitdepth,10,cm,adobe";
in {
  imports = mylib.scan_path ./.;
  ## BEGIN packages.nix
  home.packages = with pkgs; [
    (nvtopPackages.intel.override {nvidia = true;})
    minicom # embedded development
    chezmoi
    libreoffice
    qpdf
    act # Run your Github Actions locally
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
  ## BEGIN hyprland.nix
  wayland.windowManager.hyprland = {
    nvidia = true; # Prime Sync
    settings = {
      # Configure your Display resolution, offset, scale and Monitors here, use
      # `hyprctl monitors` to get the info.
      #   highres:     get the best possible resolution
      #   auto:        position automatically
      #   bitdepth,10: enable 10 bit support
      monitor = [main_monitor secondary_monitor third_monitor];
      workspace = let
        main_iface = builtins.head (lib.splitString "," main_monitor);
        secondary_iface = builtins.head (lib.splitString "," secondary_monitor);
        third_iface = builtins.head (lib.splitString "," third_monitor);
      in [
        "1,monitor:${third_iface}"
        "2,monitor:${third_iface}"
        "3,monitor:${third_iface}"
        "4,monitor:${third_iface}"
        "5,monitor:${secondary_iface}"
        "6,monitor:${secondary_iface}"
        "7,monitor:${secondary_iface}"
        "8,monitor:${main_iface}"
        "9,monitor:${main_iface}"
        "10,monitor:${main_iface}"
      ];
      env =
        [
          # "GDK_DPI_SCALE,${dpi_scale}" # Set globally is not recommend, makes firefox scale twice
          "STEAM_FORCE_DESKTOPUI_SCALING,${dpi_scale}"
        ]
        # PRIME Sync mode for Hyprland
        ++ lib.optional
        config.wayland.windowManager.hyprland.nvidia
        "AQ_DRM_DEVICES,/dev/dri/${myvars.dgpu_sym_name}:/dev/dri/${myvars.igpu_sym_name}";

      bind = [
        # Add shortcut key for Leave Mode. Leave to main monitor for sunshine streaming
        (lib.concatStrings [
          "$mainMod,Y,exec,"
          "hyprctl keyword monitor "
          "\"${builtins.head (lib.splitString "," secondary_monitor)},disable\""
          "; hyprctl keyword monitor "
          "\"${builtins.head (lib.splitString "," third_monitor)},disable\""
          "; notify-send \"Hyprland\" \"Leave mode: on\""
        ])
        # Restore the three monitors
        (lib.concatStrings [
          "$mainMod SHIFT,Y,exec,"
          "hyprctl keyword monitor \"${secondary_monitor}\""
          ";hyprctl keyword monitor \"${third_monitor}\""
          ";notify-send \"Hyprland\" \"Leave mode: off\""
        ])
      ];
      bindl = [
        # Going to dock mode if has external monitor connected
        (lib.concatStrings [
          ",switch:on:Lid Switch,exec,"
          # Hyprland interprets commands starting with [ as window rules, change
          # it to `test`
          "test $(hyprctl monitors -j | jq '.[].name' | wc -w) -ne 1"
          " && hyprctl keyword monitor \"${
            builtins.head (lib.splitString "," main_monitor)
          },disable\""
        ])
        # Restore internal monitor
        ",switch:off:Lid Switch,exec,hyprctl keyword monitor \"${main_monitor}\""
      ];
      # Cause black screen if the bandwidth doesn't enough
      # render = {cm_auto_hdr = 0; cm_fs_passthrough = 0;};
    };
  };
  programs.mpv.profiles.common.vulkan-device =
    if config.wayland.windowManager.hyprland.nvidia
    then "NVIDIA GeForce RTX 3070 Laptop GPU"
    else "Intel(R) UHD Graphics (TGL GT1)";
  ## END hyprland.nix
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
}

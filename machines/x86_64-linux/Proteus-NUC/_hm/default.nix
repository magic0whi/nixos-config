{
  config,
  lib,
  mylib,
  myvars,
  pkgs,
  ...
}: let
  monitor_cfg = {
    output = "eDP-1";
    mode = "highres";
    bitdepth = 10;
    cm = "adobe";
  };
  # Ref: https://wiki.hyprland.org/Configuring/Monitors/
  # TIP: ls /sys/class/drm/card*
  monitor_0 =
    monitor_cfg
    // {
      output = "eDP-1";
      scale = 1.25;
    }
    # 10-bit will cause the internal monitor flickering when using PRIME Sync
    // lib.optionalAttrs config.wayland.windowManager.hyprland.nvidia_prime_sync {bitdepth = 8;};
  monitor_1 =
    monitor_cfg
    // {
      output = "DP-3";
      position = "auto-up";
      scale = 1.67;
    };
  # monitor_2 =
  #   monitor_cfg
  #   // {
  #     output = "DP-3";
  #     position = "auto-up";
  #     scale = 1.67;
  #   };
in {
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
  ## BEGIN hyprland.nix
  wayland.windowManager.hyprland = {
    nvidia_prime_sync = true;
    settings = {
      # May cause black screen if the bandwidth doesn't enough, disable it
      # config.render.cm_auto_hdr = 0;

      # Configure your Display resolution, offset, scale and Monitors here, use
      # `hyprctl monitors` to get the info.
      #   highres:     get the best possible resolution
      #   auto:        position automatically
      #   bitdepth,10: enable 10 bit support
      monitor = [
        monitor_0
        monitor_1
        # monitor_2
      ];
      workspace_rule = [
        {
          workspace = "1";
          monitor = monitor_1.output;
          default = true;
          layout = "scrolling";
        }
        {
          workspace = "2";
          monitor = monitor_1.output;
          layout = "scrolling";
        }
        {
          workspace = "3";
          monitor = monitor_1.output;
        }
        {
          workspace = "4";
          monitor = monitor_1.output;
        }
        {
          workspace = "5";
          monitor = monitor_1.output;
        }
        {
          workspace = "6";
          monitor = monitor_1.output;
        }
        {
          workspace = "7";
          monitor = monitor_1.output;
        }
        {
          workspace = "8";
          monitor = monitor_1.output;
        }
        {
          workspace = "9";
          monitor = monitor_1.output;
        }
        {
          workspace = "10";
          monitor = monitor_0.output;
        }
        # "2,monitor:${third_iface}"
        # "3,monitor:${third_iface}"
        # "4,monitor:${third_iface}"
        # "5,monitor:${secondary_iface}"
        # "6,monitor:${secondary_iface}"
        # "7,monitor:${secondary_iface}"
        # "8,monitor:${main_iface}"
        # "9,monitor:${main_iface}"
        # "10,monitor:${main_iface}"
      ];
      # NOTE: Set "GDK_DPI_SCALE" globally is not recommend, makes firefox scale twice
      env =
        [
          {_args = ["STEAM_FORCE_DESKTOPUI_SCALING" "${toString monitor_1.scale}"];}
        ]
        # PRIME Sync mode for Hyprland
        ++ lib.optional
        config.wayland.windowManager.hyprland.nvidia_prime_sync
        {_args = ["AQ_DRM_DEVICES" "/dev/dri/${myvars.dgpu_sym_name}:/dev/dri/${myvars.igpu_sym_name}"];};

      bind = [
        # Add shortcut key for Leave Mode. Leave to main monitor for sunshine streaming
        {
          _args = [
            (lib.generators.mkLuaInline ''main_mod .. " + Y"'')
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${
                builtins.concatStringsSep "; " [
                  ''hyprctl dispatch 'hl.monitor({ output = \"${monitor_0.output}\", disabled = true })' ''
                  ''notify-send 'Hyprland' 'Leave mode: on' ''
                ]
              }")'')
            {locked = true;}
          ];
        }
        # Restore the monitors
        {
          _args = [
            (lib.generators.mkLuaInline ''main_mod .. " + SHIFT + Y"'')
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${
                builtins.concatStringsSep "; " [
                  "hyprctl reload"
                  ''notify-send 'Hyprland' 'Leave mode: off' ''
                ]
              }")'')
          ];
        }
        # Going to dock mode if has external monitor connected
        {
          _args = [
            (lib.generators.mkLuaInline ''"switch:on:Lid Switch"'')
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${
                builtins.concatStringsSep " " [
                  # Hyprland interprets commands starting with [ as window rules, change it to `test`, same as Lua
                  # Config
                  "test $(hyprctl -j monitors | jq '.[].name' | wc -w) -ne 1"
                  ''&& hyprctl dispatch 'hl.monitor({ output = \"${monitor_0.output}\", disabled = true })' ''
                ]
              }")'')
          ];
        }
        # Restore internal monitor
        {
          _args = [
            (lib.generators.mkLuaInline ''"switch:off:Lid Switch"'')
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("hyprctl reload")'')
          ];
        }
      ];
    };
  };
  programs.mpv.profiles.common.vulkan-device =
    if config.wayland.windowManager.hyprland.nvidia_prime_sync
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

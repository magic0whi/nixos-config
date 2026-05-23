{
  config,
  mylib,
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
    witr
  ];
  ## END packages.nix
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

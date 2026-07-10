# NOTE:
# - impermanence will mounts the dirs/files list below to /persistent. If the directory/file already exists in the root
#   filesystem, you should move those files/directories to /persistent first!
# - Impermance can not coexist with `config.system.build.images.iso`, don't import this file if you wanna generate
#   bootable iso
# - Impermance is not compatible with `system.etc.overlay.enable`
#
# TIP: to show impermanence usage, run `sudo ncdu -x /`
#
# There are two ways to clear the root filesystem on every boot:
# - Use tmpfs for /
# - (btrfs/zfs only) take a blank snapshot of the root filesystem and revert to it on every boot via:
#   boot.initrd.postDeviceCommands = ''
#     mkdir -p /run/mymount
#     mount -o subvol=/ /dev/disk/by-uuid/UUID /run/mymount
#     btrfs subvolume delete /run/mymount
#     btrfs subvolume snapshot / /run/mymount
#   '';
#   See also https://grahamc.com/blog/erase-your-darlings/
{
  config,
  lib,
  const,
  pkgs,
  ...
}:
{
  fileSystems = lib.mkMerge [
    { "/persistent".neededForBoot = true; }
    (lib.mkIf (config ? home-manager) { "/home".neededForBoot = true; })
  ];

  environment.persistence."/persistent" = {
    # Sets the mount option x-gvfs-hide on all the bind mounts to hide them from the file manager
    hideMounts = true;
    directories = [
      "/etc/ssh"
      "/etc/nix/inputs"

      "/var/log"
      "/var/lib"
    ];
    files = [ "/etc/machine-id" ];

    users = lib.mkIf (config ? home-manager) {
      ${const.username} =
        let
          hm_cfg = config.home-manager.users.${const.username};
        in
        {
          # The following directories will be passed to /persistent/home/$USER
          directories = [
            {
              directory = ".ssh";
              mode = "0700";
            }

            # Misc
            ".config/pulse"
            ".pki"

            # Cloud native
            # TODO: Try pulumi - infrastructure as code
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

            # TODO: Try emacs
            # doom-emacs
            # ".config/emacs"

            # neovim / remmina / flatpak / ...
            # Since the `$XDG_DATA_HOME/Trash` is usually `~/.local/share/Trash`
            # Programs following freedesktop.org trash specification will refuse
            # to delete files that not coverd by impermance
            ".local/share"
            ".local/state"

            # neovim plugins (wakatime & copilot)
            # ".wakatime"
            # ".config/github-copilot"
          ]
          ++ lib.optional hm_cfg.programs.gpg.enable {
            directory = ".gnupg";
            mode = "0700";
          }
          ++ lib.optionals hm_cfg.xdg.enable (
            map (p: baseNameOf p) (
              with hm_cfg.xdg.userDirs;
              [
                desktop
                documents
                download
                music
                pictures
                projects
                videos
              ]
            )
          )
          ++ lib.optional config.programs.steam.enable ".steam"
          # Remote Desktop
          ++ lib.optional (builtins.elem pkgs.remmina hm_cfg.home.packages) ".config/remmina"
          ++ lib.optional (builtins.elem pkgs.freerdp hm_cfg.home.packages) ".config/freerdp"
          ++ lib.optionals hm_cfg.programs.vscode.enable [
            ".vscode"
            ".vscode-insiders"
            ".config/Code/User"
            ".config/Code - Insiders/User"
          ]
          # Browsers
          ++ lib.optional hm_cfg.programs.firefox.enable ".mozilla"
          ++ lib.optional hm_cfg.programs.google-chrome.enable ".config/google-chrome"
          ++ lib.optional (builtins.elem pkgs.blender hm_cfg.home.packages) ".config/blender"
          # Cloud Providers
          ++ lib.optional (builtins.elem pkgs.google-cloud-sdk hm_cfg.home.packages) ".config/gcloud"
          ++ lib.optional (builtins.elem pkgs.terraform hm_cfg.home.packages) ".config/terraform.d"
          ++ lib.optional (builtins.elem pkgs.ldtk hm_cfg.home.packages) ".config/LDtk";
          # files = [".wakatime.cfg"];
        };
    };
  };
}

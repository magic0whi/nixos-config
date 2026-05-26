{
  config,
  lib,
  myvars,
  ...
}:
{
  # NOTE:
  # - Impermance can not coexist with nixos-generators, don't import this file if you wanna generate bootable iso
  # - Impermance is not compatible with `system.etc.overlay.enable`
  # TIP: to show impermanence usage, run `sudo ncdu -x /`
  config = lib.mkIf (config.environment ? persistence) {
    # There are two ways to clear the root filesystem on every boot:
    # 1. Use tmpfs for /
    # 2. (btrfs/zfs only) take a blank snapshot of the root filesystem and revert to it on every boot via:
    #   boot.initrd.postDeviceCommands = ''
    #     mkdir -p /run/mymount
    #     mount -o subvol=/ /dev/disk/by-uuid/UUID /run/mymount
    #     btrfs subvolume delete /run/mymount
    #     btrfs subvolume snapshot / /run/mymount
    #   '';
    #   See also https://grahamc.com/blog/erase-your-darlings/

    boot.initrd.systemd.enable = true; # Hibernate alse requires this
    fileSystems."/persistent".neededForBoot = true;
    # The assertion will throw even without set
    # `environment.persistence."/persistent".users.${myvars.username}`
    fileSystems."/home".neededForBoot = true;

    # NOTE: impermanence only mounts the directory/file list below to /persistent. If the directory/file already exists in
    # the root filesystem, you should move those files/directories to /persistent first!
    environment.persistence."/persistent" = {
      # Sets the mount option x-gvfs-hide on all the bind mounts to hide them from the file manager
      hideMounts = true;
      directories = [
        "/etc/ssh"
        "/etc/nix/inputs"

        "/var/log"
        "/var/lib"
      ];
      # ++ lib.optional config.boot.lanzaboote.enable config.boot.lanzaboote.pkiBundle; # If lanzaboote is enabled. Disable since we got its parent `/var/lib` persistent already

      files = [ "/etc/machine-id" ];

      users.${myvars.username} = {
        # The following directories will be passed to /persistent/home/$USER
        directories = [
          {
            directory = ".gnupg";
            mode = "0700";
          }
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
        ];
        # files = [".wakatime.cfg"];
      };
    };
  };
}

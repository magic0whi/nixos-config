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
  ...
}:
let
  hm_enabled = config ? home-manager;
in
{
  fileSystems = lib.mkMerge [
    { "/persistent".neededForBoot = true; }
    (lib.mkIf hm_enabled { "/home".neededForBoot = true; })
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

    users = lib.mkIf hm_enabled {
      # The following directories will be passed to /persistent/home/$USER
      ${const.username}.directories = [
        {
          directory = ".ssh";
          mode = "0700";
        }
        ".pki"

        # TODO: Try emacs
        # doom-emacs
        # ".config/emacs"

        # neovim / flatpak / ...
        # `$XDG_DATA_HOME/Trash` is usually `~/.local/share/Trash` and programs following
        # freedesktop.org trash spec refuse to trash files that are not coverd by impermanence
        ".local/share"
        ".local/state"
      ];
      # files = [".wakatime.cfg"];
    };
  };
}

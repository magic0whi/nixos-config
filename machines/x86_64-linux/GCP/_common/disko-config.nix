{
  disko.devices.disk.main.content.partitions.root = {
    type = "CA7D7CCB-63ED-4C53-861C-1742536059CC"; # Linux LUKS
    size = "100%";
    content = {
      type = "luks";
      name = "crypted-root";
      extraFormatArgs = [ "--pbkdf-memory=${toString (64 * 1024)}" ];
      # passwordFile = builtins.toFile "secret.key" "vmtest"; # NOTE comment-out on deploy
      settings = {
        # keyFile = "/etc/dm_keyfile.key";
        # keyFileTimeout = 15;
        allowDiscards = true;
        bypassWorkqueues = true;
        # fallbackToPassword = false;
      };
      content = {
        type = "btrfs";
        # extraArgs = [ "-f" ]; # Override existing partition
        # Subvolumes must set a mountpoint in order to be mounted, unless their parent is mounted
        subvolumes =
          let
            mountOptions = [
              "discard=async"
              "compress=zstd"
              "noatime"
            ];
          in
          {
            # NOTE: @ is a convention for subvolume, make it discerning from direcroties
            "@root" = {
              mountpoint = "/";
              inherit mountOptions;
            };
            # Home Manager requires the /home mountpoint to be exist
            "@home" = {
              mountpoint = "/home";
              inherit mountOptions;
            };
            "@nix" = {
              mountpoint = "/nix";
              inherit mountOptions;
            };
            "@persistent" = {
              mountpoint = "/persistent";
              inherit mountOptions;
            };
            "@swap" = {
              mountpoint = "/.swapvol";
              # NOTE: You can't set per-subvolume nodatacow, nodatasum, or compress using mount options
              # https://btrfs.readthedocs.io/en/latest/Administration.html
              mountOptions = [
                "discard=async"
                "noatime"
              ];
              swap = {
                swapfile.size = "2G";
                # swapfile2 = {
                #   size = "20M";
                #   path = "rel-path";
                # };
              };
            };
          };
        # mountpoint = "/btrfs-root";
        # swap = { # swapfiles under `/btrfs-root`
        #   swapfile.size = "20M";
        #   swapfile1.size = "20M";
        # };
      };
    };
  };
}

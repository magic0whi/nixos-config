{
  disko.devices.disk.main.content.partitions.root = {
    type = "0FC63DAF-8483-4772-8E79-3D69D8477DE4"; # Linux filesystem
    size = "100%";
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
}

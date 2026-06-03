{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/virtio-46703ba9-e5b8-47e1-b";
    content = {
      type = "gpt";
      partitions = {
        # For GRUB MBR
        boot = {
          priority = 1;
          size = "1M";
          # disko hardcoded "EF02" in https://github.com/nix-community/disko/blob/916506443ecd0d0b4a0f4cf9d40a3c22ce39b378/lib/types/gpt.nix#L378
          # so set it to "024DEE41-33E7-11D3-9D69-0008C781F39F" makes
          # `boot.loader.grub.devices` not automatically set
          type = "EF02";
          attributes = [ 0 ]; # Partition attribute
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@root" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd" ];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@persistent" = {
                mountpoint = "/persistent";
                mountOptions = [ "compress=zstd" ];
              };
              "@swap" = {
                mountpoint = "/.swapvol";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
                swap.swapfile.size = "2G";
              };
            };
          };
        };
      };
    };
  };
}

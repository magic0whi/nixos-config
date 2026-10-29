{ pkgs, ... }:
{
  services = {
    printing.enable = true; # Enable CUPS to print documents.
    geoclue2.enable = true; # Enable geolocation services.
    udev.packages = with pkgs; [
      platformio # udev rules for platformio
      openocd # Required by paltformio, ref: https://github.com/NixOS/nixpkgs/issues/224895
      openfpgaloader
    ];
    # A key remapping daemon for Linux, ref: https://github.com/rvaiya/keyd
    keyd = {
      enable = true;
      keyboards.default.settings = {
        main = {
          # Overloads the capslock key to function as both escape (when tapped) and control (when held)
          capslock = "overload(control, esc)";
          # Mimic macOS: tap to toggle 中/英 (send Ctrl + Space, fcitx5's default), hold for capslock
          # Ref: https://github.com/rvaiya/keyd/blob/f564288ac2b19d2305a5b39023c474805ff8fce5/docs/keyd.scdoc#L754
          esc = "timeout(C-space, 300, capslock)";
        };
      };
    };
  };
  # To test:
  # `udevadm info --query=path --name=/dev/sda`
  # `sudo udevadm test -a add $(ls -d /sys/block/sda/device/scsi_disk/*)`
  # `sudo udevadm test -a add /devices/pci0000:00/0000:00:14.0/usb4/4-1/4-1:1.0/host0/target0:0:0/0:0:0:0/block/sda`
  services.udev.extraRules = ''
    # USB SSD Trim
    ACTION=="change", SUBSYSTEM=="scsi_disk", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="a583", ATTR{provisioning_mode}="unmap"
    ACTION=="add", SUBSYSTEM=="block", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="a583", RUN+="${pkgs.systemd}/bin/udevadm trigger --action=change --subsystem-match=scsi_disk"
  '';
}

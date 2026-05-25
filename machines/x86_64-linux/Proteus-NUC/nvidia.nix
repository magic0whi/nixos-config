{
  lib,
  myvars,
  ...
}:
{
  boot.blacklistedKernelModules = [ "nova_core" ];
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    dynamicBoost.enable = true;
    open = true;
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    prime =
      let
        # "0001:02:03.4" to "PCI:2@1:3:4", in which the order is "PCI:bus@domain:device:func"
        to_nixos_bus_id =
          pci_ids:
          let
            hex_to_int = hex: toString (lib.fromHexString hex);

            colon_splited = lib.splitString ":" pci_ids;
            domain = hex_to_int (builtins.head colon_splited);
            bus = hex_to_int (builtins.elemAt colon_splited 1);

            dot_splited = lib.splitString "." (lib.last colon_splited);
            device = hex_to_int (builtins.head dot_splited);
            func = hex_to_int (lib.last dot_splited);
          in
          "PCI:${bus}@${domain}:${device}:${func}";
      in
      {
        # NOTE: It's unnecessary to use sync.enable for hybrid laptop since it only affect Xorg server related configs
        # Ref (search for keyword `syncCfg.enable`):
        # https://github.com/NixOS/nixpkgs/blob/6c9a78c09ff4d6c21d0319114873508a6ec01655/nixos/modules/hardware/video/nvidia.nix#L508
        intelBusId = to_nixos_bus_id myvars.igpu_pci_ids;
        nvidiaBusId = to_nixos_bus_id myvars.dgpu_pci_ids;
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
      };
  };
  services.udev.extraRules = ''
    # Consistent device paths for specific cards
    KERNEL=="card*", KERNELS=="${myvars.igpu_pci_ids}", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/${myvars.igpu_sym_name}"
    KERNEL=="card*", KERNELS=="${myvars.dgpu_pci_ids}", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/${myvars.dgpu_sym_name}"
  '';
}

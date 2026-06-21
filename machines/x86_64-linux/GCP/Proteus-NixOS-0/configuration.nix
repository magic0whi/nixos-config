{ lib, const, ... }:
{
  time.timeZone = "America/Los_Angeles";
  # To test, run `nix run .#nixosConfigurations.<name>.config.system.build.vmWithDisk`
  # Configurations only apply to vmWithDisko
  virtualisation.vmVariantWithDisko = {
    # https://github.com/nix-community/disko/issues/1157#issuecomment-3559146597
    users.users.${const.username}.initialHashedPassword = const.initial_hashed_password;
    virtualisation.fileSystems = {
      "/home".neededForBoot = true;
      "/persistent".neededForBoot = lib.mkForce true;
    };
  };

  # BEGIN disko-config.nix
  disko.devices.disk.main.device = "/dev/disk/by-id/scsi-0Google_PersistentDisk_proteus-nixos-0";
  # END disko-config.nix
  # services.cloud-init = {
  #   enable = true;
  #   network.enable = true; # Let cloud-init manage networking/DNS
  #   settings = {
  #     preserve_hostname = true; # Let NixOS manage hostname
  #     manage_etc_hosts = false; # Let NixOS manage /etc/hosts
  #     datasource_list = ["GCE"];
  #   };
  # };
  # networking.useDHCP = false; # cloud-init
  # boot.binfmt.emulatedSystems = [ "riscv64-linux" ]; # Cross compilation
}

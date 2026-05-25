_: {
  time.timeZone = "America/Los_Angeles";
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

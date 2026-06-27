{ config, ... }:
{
  vars.hostAddrs.${config.networking.hostName}.wire.ipv4 = "192.168.1.26";
  boot.loader.systemd-boot.enable = false;
}

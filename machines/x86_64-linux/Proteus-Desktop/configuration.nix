{
  config,
  lib,
  mylib,
  const,
  pkgs,
  ...
}:
let
  hostname = config.networking.hostName;
in
{
  ## BEGIN network.nix
  vars.hostAddrs.${hostname} =
    let
      regHost = true;
    in
    {
      tailscale = {
        inherit regHost;
        ipv4 = "100.89.227.22/10";
        ipv6 = "fd7a:115c:a1e0::1a01:e318/48";
      };
      easytier = {
        inherit regHost;
        ipv4 = "10.0.0.3/24";
        ipv6 = "fdfe:dcba:9877::3/64";
      };
      wire = {
        name = "enp4s0";
        ipv4 = builtins.head config.systemd.network.networks."10-wire".address;
      };
    };
  systemd.network.networks."10-wire" = {
    inherit (config.vars.hostAddrs.${hostname}.wire) name;
    address = [ "192.168.1.20/24" ];
    gateway = [ "192.168.1.1" ];
    DHCP = "no";
    networkConfig.IPv6AcceptRA = true;
  };
  networking.firewall.extraInputRules = ''
    ip saddr 192.168.1.21 accept comment "Allow LAN AP clients to reach auto_redirect ports"
  '';
  ## END network.nix
  ## BEGIN hardware.nix
  boot.initrd.availableKernelModules = lib.optional config.boot.initrd.systemd.network.enable "r8169";
  # hybrid have VAProfileVP9Profile0 support
  hardware.graphics.extraPackages = [ (pkgs.intel-vaapi-driver.override { enableHybridCodec = true; }) ];
  environment.systemPackages = [ pkgs.smartmontools ];
  ## END hardware.nix
  ## BEGIN sing-box-client.nix
  services.resolved.settings.Resolve.DNSStubListenerExtra = [ config.vars.hostAddrs.${hostname}.wire.ipv4NoCidr ]; # for split DNS
  # lib.mkForce to prevent merge
  services.sing-box.settings = lib.mkForce (
    import (mylib.relativeToRoot "modules/common/_sing-box-client") {
      inherit
        config
        lib
        mylib
        const
        pkgs
        ;
      # Disable FakeIP-only mode as I run hostapd on this machine
      # isServer = true;
      # isRouter = true;
    }
  );
  # Ref: https://wiki.archlinux.org/title/Sysctl#Change_TCP_keepalive_parameters
  boot.kernel.sysctl = {
    "net.ipv4.tcp_keepalive_time" = 60; # Default: 7200s (2 hrs). Start probing after 60 seconds of idle
    "net.ipv4.tcp_keepalive_intvl" = 10; # Default: 75s Probe every 10 seconds
    "net.ipv4.tcp_keepalive_probes" = 6; # Default: 9. Drop connection after 6 failed probes
  };
  ## END sing-box-client.nix
  ## BEGIN zfs.nix
  networking.hostId = "953b2f69"; # ZFS requires this
  ## END zfs.nix
  ## BEGIN systemd_tmpfiles.nix
  # systemd.tmpfiles.settings = {
  #   # Setgid so new files inherit group; give rw to group members
  #   "00-create-data-share"."${const.storagePath}/share".d = {group = "storage"; mode = "2775";};
  #   # Even with setgid, services may create files with restrictive umasks. Lock in permissions with default ACLs
  #   # TIP: You may change type to `A+` to recursively modify exists dirs/files' ACLs
  #   # TIP: Run `getfacl /path` to show rule list
  #   "01-acl-data-share-default"."${const.storagePath}/share"."a+".argument = "d:g:storage:rwX";
  #   "01-acl-data-share"."${const.storagePath}/share".a.argument = "g:storage:rwX";
  # };
  ## END systemd_tmpfiles.nix
}

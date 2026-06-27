{
  config,
  lib,
  mylib,
  const,
  pkgs,
  ...
}:
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      regHost = true;
      subdomains =
        let
          sub = [ "ql" ];
        in
        {
          A = sub;
          AAAA = sub;
        };
    in
    {
      tailscale = {
        inherit regHost;
        ipv4 = "100.89.227.22/10";
        ipv6 = "fd7a:115c:a1e0::1a01:e318/48";
        subdomains = subdomains;
      };
      easytier = {
        inherit regHost;
        ipv4 = "10.0.0.3/24";
        ipv6 = "fdfe:dcba:9877::3/64";
        inherit subdomains;
      };
      wire.name = "enp4s0";
      wireless = {
        name = "wlp0s20u9";
        ipv4 = "192.168.12.1/24";
      };
    };
  ## BEGIN hardware.nix
  boot.initrd.availableKernelModules = lib.optional config.boot.initrd.systemd.network.enable "r8169";
  # hybrid have VAProfileVP9Profile0 support
  hardware.graphics.extraPackages = [ (pkgs.intel-vaapi-driver.override { enableHybridCodec = true; }) ];
  ## END hardware.nix
  ## BEGIN sing-box-client.nix
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
      isServer = true;
    }
  );
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

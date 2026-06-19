{
  config,
  lib,
  mylib,
  const,
  pkgs,
  ...
}:
{
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
  boot.binfmt.emulatedSystems = [ "riscv64-linux" ]; # Cross compilation
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
  ## vaapi.nix
  # hybrid have VAProfileVP9Profile0 support
  hardware.graphics.extraPackages = [ (pkgs.intel-vaapi-driver.override { enableHybridCodec = true; }) ];
  ## vaapi.nix
}

{ config, const, ... }:
{
  # Rollback `/` to blank snapshot on boot
  boot.initrd.systemd.services."zfs-rollback-root" = {
    description = "Rollback zroot/root@blank in initrd";
    wantedBy = [ "zfs-import.target" ];
    after = [ "zfs-import-zroot.service" ]; # Make sure zroot is imported
    before = [ "sysroot.mount" ]; # Make sure this happens before root is mounted
    serviceConfig = {
      Type = "oneshot";
      # `-r` destroys any snapshots and bookmarks more recent than the one specified
      ExecStart = "${config.boot.zfs.package}/sbin/zfs rollback -r zroot/root@blank";
    };
  };

  environment.persistence."/persistent".directories = [ "/srv" ];
  environment.persistence."/persistent".users.${const.username}.directories = [
    "Proteus"

    # IM
    # ".config/QQ"
    # ".xwechat"
  ];
}

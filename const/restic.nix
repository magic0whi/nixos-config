# - To initialize the repository (one-time): restic-<Hostname> init
# - To check backup status: restic-<Hostname> snapshots
# - To retrieve latest snapshots:
#   restic-<Hostname> latest --target /tmp/restic-restore
#   restic-<Hostname> <Snapshot ID> --target /tmp/restic-restore
lib: username: backup_time: config: {
  user = username; # Default root, set to primary user to ease the use of `restic-<Hostname>` command
  initialize = true; # Create the repository if it doesn’t exist
  passwordFile = config.sops.secrets.restic_password.path; # Password for restic backup itself
  # An environment file for your storage provider credentials (e.g., AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
  environmentFile = lib.mkDefault config.sops.templates."restic_main.env".path;

  # Retention policy
  pruneOpts = [
    "--keep-daily 7"
    "--keep-weekly 5"
    "--keep-monthly 12"
    "--keep-yearly 75"
  ];
  checkOpts = [ "--with-cache" ]; # Reuse existing cache
  # Run backup + prune + check weekly (Sundays at 3 AM)
  timerConfig = {
    OnCalendar = lib.mkDefault backup_time;
    # RandomizedDelaySec = "30m"; # Jitter
    Persistent = lib.mkDefault true; # Run immediately if system was off at scheduled time
  };
  # Performance tuning
  extraBackupArgs = [ "--limit-upload ${toString (50 * 1024)}" ];
  # Limit upload speed to 50 MB/s, unit is KiB/s
  extraOptions = [ "read-concurrency=4" ]; # Read concurrency for better throughput on ZFS
  # Paths to exclude from backup
  exclude = [
    "**/.Trash"
    "**/node_modules"
    # Cache directories
    "*/.cache"
    "*/cache"
  ];
}
